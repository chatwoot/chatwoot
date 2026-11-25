require 'rails_helper'

# These run against a real Redis: MockRedis (which the app's own pools use in tests)
# implements none of the stream or blocking commands this depends on.
RSpec.describe Whatsapp::Connector::Client, :redis_streams do
  subject(:client) { described_class.new(session_id) }

  let(:session_id) { '9f1c0f4e-6a2b-4c8e-9d1a-2b3c4d5e6f70' }
  let(:prefix) { "watest#{SecureRandom.hex(4)}:" }
  let(:model) { Whatsapp::Session::Model }
  let(:redis) { Redis.new(Redis::Config.app) }
  let(:command) { model::Commands::SessionStatus.new }

  around do |example|
    with_modified_env(WHATSAPP_CONNECTOR_REDIS_PREFIX: prefix) { example.run }
    keys = redis.keys("#{prefix}*")
    redis.del(*keys) if keys.any?
  end

  def frame_of(entry)
    entry.last.transform_values { |value| value.start_with?('{') ? JSON.parse(value) : value }
  end

  describe '#publish' do
    it 'queues the command on the stream of its session' do
      id = client.publish(model::Commands::SessionDisconnect.new)

      entries = redis.xrange("#{prefix}cmd:#{session_id}")
      expect(entries.size).to eq(1)
      frame = frame_of(entries.first)
      expect(frame).to include('v' => '1', 'type' => 'session.disconnect', 'sid' => session_id, 'id' => id)
      # Fire and forget: nothing is waiting for an answer.
      expect(frame).not_to have_key('reply_to')
    end

    # An empty registry is fine: the stream holds the frame until a connector comes up
    # and reads it, which is the whole point of not waiting for an answer.
    it 'queues the command with nobody listening yet' do
      expect { client.publish(model::Commands::SessionDisconnect.new) }.not_to raise_error
    end

    # A connector that is up and speaks another protocol is not the same thing: it reads
    # the frame and drops it, while the caller is told the command was queued. A logout
    # or a delete discarded that way leaves the session paired, and the conversion or the
    # destruction that asked for it reports success.
    # The connector reads `deadline` whether or not a reply was asked for: it refuses a
    # command whose deadline passed before it was reached, and it bounds the execution of
    # one it does run. A published command has no caller waiting on it to give up, so the
    # ceiling the frame declares is the only one it gets.
    it 'bounds a published command by the ceiling its caller declared' do
      client.publish(model::Commands::ChatPresence.new(chat: model::Address.phone('5541999990000'), state: 'composing'),
                     timeout: 30)

      frame = frame_of(redis.xrange("#{prefix}cmd:#{session_id}").first)
      expect(frame['deadline'].to_i - frame['ts'].to_i).to eq(30_000)
      # Still fire and forget: the ceiling is for the connector, not for a caller waiting.
      expect(frame).not_to have_key('reply_to')
    end

    # The other ceiling, and the teardown is what it exists for: published exactly so it can
    # sit pending while the session is between owners, it cannot take a deadline without
    # becoming droppable, and a `session.logout` dropped for arriving late leaves the device
    # listed on the customer's phone. This one is a duration the connector starts counting
    # when the work does, so queueing time never eats into it.
    it 'bounds a published command by how long it may run once it starts' do
      client.publish(model::Commands::SessionLogout.new, max_runtime: 30)

      frame = frame_of(redis.xrange("#{prefix}cmd:#{session_id}").first)
      expect(frame['max_runtime_ms'].to_i).to eq(30_000)
      # An instant would be the wrong half, and sending both would reintroduce it.
      expect(frame).not_to have_key('deadline')
    end

    it 'leaves a published command unbounded when its caller declared no ceiling' do
      client.publish(model::Commands::SessionLogout.new)

      frame = frame_of(redis.xrange("#{prefix}cmd:#{session_id}").first)
      expect(frame).not_to have_key('deadline')
      expect(frame).not_to have_key('max_runtime_ms')
    end

    it 'refuses to queue for a connector that speaks another protocol' do
      redis.hset("#{prefix}instance:one", 'protocol_min', '2', 'protocol_max', '3')
      redis.sadd("#{prefix}instances", 'one')

      expect { client.publish(model::Commands::SessionDisconnect.new) }
        .to raise_error(Whatsapp::Session::Errors::ProviderUnavailable, /speaks protocol 1/)
    end
  end

  describe '#call' do
    before { redis.hset("#{prefix}instance:one", 'protocol_min', '1', 'protocol_max', '1') && redis.sadd("#{prefix}instances", 'one') }

    it 'sends the command with a deadline and returns what the connector answered' do
      allow(SecureRandom).to receive(:uuid).and_return('cmd-0001')
      redis.lpush("#{prefix}reply:cmd-0001", { 'v' => 1, 'id' => 'cmd-0001', 'ok' => true,
                                               'result' => { 'connection' => 'open' } }.to_json)

      expect(client.call(command)).to eq({ 'connection' => 'open' })

      frame = frame_of(redis.xrange("#{prefix}cmd:#{session_id}").first)
      expect(frame['reply_to']).to eq("#{prefix}reply:cmd-0001")
      # Shorter than the caller's own wait by the margin, so the connector stops working
      # on the command before the caller stops caring about the answer.
      expect(frame['deadline'].to_i - frame['ts'].to_i)
        .to eq((described_class::RPC_TIMEOUT - described_class::DEADLINE_MARGIN) * 1000)
    end

    it 'raises the error the connector reported, mapped to its class' do
      allow(SecureRandom).to receive(:uuid).and_return('cmd-0002')
      redis.lpush("#{prefix}reply:cmd-0002", { 'v' => 1, 'id' => 'cmd-0002', 'ok' => false,
                                               'error' => { 'code' => 'not_connected', 'message' => 'session is closed' } }.to_json)

      expect { client.call(command) }.to raise_error(Whatsapp::Session::Errors::NotConnected, /session is closed/)
    end

    it 'gives up when nobody answers' do
      expect { client.call(command, timeout: 1) }.to raise_error(Whatsapp::Session::Errors::Timeout)
    end

    it 'refuses to queue anything while no connector is running' do
      redis.del("#{prefix}instances")

      expect { client.call(command) }.to raise_error(Whatsapp::Session::Errors::ProviderUnavailable, /no whatsapp connector is running/)
      expect(redis.exists?("#{prefix}cmd:#{session_id}")).to be(false)
    end

    it 'refuses to queue a frame the running connector has moved past' do
      redis.hset("#{prefix}instance:one", 'protocol_min', '2', 'protocol_max', '3')

      expect { client.call(command) }.to raise_error(Whatsapp::Session::Errors::ProviderUnavailable, /speaks protocol 1/)
      expect(redis.exists?("#{prefix}cmd:#{session_id}")).to be(false)
    end
  end

  # The control stream carries both kinds: a `session.wake` any instance may take and
  # nobody waits on, and an `admin.ping` that answers. The margin belongs to the one that
  # answers, and a wake that carried a deadline could be dropped for arriving late at the
  # very moment there is no owner to take the session -- which is when it is sent.
  describe '#control' do
    it 'leaves a control command that answers nothing unbounded' do
      client.control(model::Commands::SessionWake.new(desired: 'connected'))

      frame = frame_of(redis.xrange("#{prefix}control").first)
      expect(frame).not_to have_key('reply_to')
      expect(frame).not_to have_key('deadline')
      expect(frame).not_to have_key('max_runtime_ms')
    end

    # The teardown of a session nobody is running goes through this door, and it needs the
    # same ceiling as the half that rides the session's own stream: the executor it holds
    # is the one the connector adopted for the length of the teardown.
    it 'carries a runtime ceiling on a control command that asks for one' do
      client.control(model::Commands::SessionDelete.new, max_runtime: 30)

      frame = frame_of(redis.xrange("#{prefix}control").first)
      expect(frame['max_runtime_ms'].to_i).to eq(30_000)
      expect(frame).not_to have_key('deadline')
    end

    # The wake used to be the only caller here, and what refused a connector speaking
    # another protocol was the `call` that `connect` makes right after it. A teardown has
    # no call behind it: written to a connector that reads the frame and drops it, the
    # caller is told it was queued, and the device stays listed on the customer's phone
    # with the inbox already destroyed.
    it 'refuses to queue for a connector that speaks another protocol' do
      redis.hset("#{prefix}instance:one", 'protocol_min', '2', 'protocol_max', '3')
      redis.sadd("#{prefix}instances", 'one')

      expect { client.control(model::Commands::SessionDelete.new) }
        .to raise_error(Whatsapp::Session::Errors::ProviderUnavailable, /speaks protocol 1/)
      expect(redis.exists?("#{prefix}control")).to be(false)
    end

    # An empty registry is a different thing, and it is fine for the same reason it is on
    # publish: the stream holds the frame until a connector comes up and reads it, which
    # is what a teardown nobody waits on is for.
    it 'queues a control command with nobody listening yet' do
      expect { client.control(model::Commands::SessionDelete.new) }.not_to raise_error
      expect(redis.xrange("#{prefix}control").size).to eq(1)
    end

    it 'bounds a control command that answers the way it bounds an RPC' do
      allow(SecureRandom).to receive(:uuid).and_return('cmd-0003')
      redis.lpush("#{prefix}reply:cmd-0003", { 'v' => 1, 'id' => 'cmd-0003', 'ok' => true, 'result' => {} }.to_json)

      client.control(model::Commands::AdminPing.new)

      frame = frame_of(redis.xrange("#{prefix}control").first)
      expect(frame['reply_to']).to eq("#{prefix}reply:cmd-0003")
      expect(frame['deadline'].to_i - frame['ts'].to_i)
        .to eq((described_class::RPC_TIMEOUT - described_class::DEADLINE_MARGIN) * 1000)
    end
  end

  # Raw, a checkout timeout reaches the send path as a 500: everything above this layer
  # rescues Whatsapp::Session::Errors, and a connection it could not get means the same
  # to them as a connector it could not reach.
  it 'answers a pool that has nothing free in the layer own errors' do
    allow(described_class).to receive(:pool).and_raise(ConnectionPool::TimeoutError, 'waited 5 seconds')

    expect { client.publish(model::Commands::SessionDisconnect.new) }
      .to raise_error(Whatsapp::Session::Errors::ProviderUnavailable, /no connector connection available/)
  end

  # Everything above this layer rescues Whatsapp::Session::Errors and nothing else, and
  # the jobs that retry do it on ProviderUnavailable, so a Redis outage that arrived raw
  # reached a group controller or a send as a 500 and skipped the retry meant for it.
  it 'answers a Redis that is not there in the layer own errors' do
    allow_any_instance_of(Redis).to receive(:xadd).and_raise(Redis::CannotConnectError, 'connection refused') # rubocop:disable RSpec/AnyInstance

    expect { client.publish(model::Commands::SessionDisconnect.new) }
      .to raise_error(Whatsapp::Session::Errors::ProviderUnavailable, /transport failed/)
  end

  describe 'the instance registry' do
    it 'reports nobody home when no instance is registered' do
      expect(client).not_to be_available
      expect(client).not_to be_compatible
    end

    it 'is compatible when the protocol ranges overlap' do
      redis.hset("#{prefix}instance:one", 'protocol_min', '1', 'protocol_max', '2', 'media_token', 'secret')
      redis.sadd("#{prefix}instances", 'one')

      expect(client).to be_available
      expect(client).to be_compatible
    end

    # A blob lives on the instance that downloaded it, and each instance only accepts the
    # token it published, so picking whichever the registry listed first got a 401 on
    # every blob that happened to belong to another one.
    it 'answers with the media token of the instance serving the URL' do
      redis.hset("#{prefix}instance:one", 'advertise_url', 'http://wa-1:8080', 'media_token', 'token-one')
      redis.hset("#{prefix}instance:two", 'advertise_url', 'http://wa-2:8080', 'media_token', 'token-two')
      redis.sadd("#{prefix}instances", %w[one two])

      expect(client.media_token('http://wa-2:8080/media/abc')).to eq('token-two')
      expect(client.media_token('http://wa-1:8080/media/abc')).to eq('token-one')
    end

    # The hashes expire but the set does not, so an instance that crashed or came back
    # under a new id stayed a member for good and every send paid a round trip for it.
    it 'drops members whose instance is gone' do
      redis.hset("#{prefix}instance:one", 'protocol_min', '1', 'protocol_max', '1')
      redis.sadd("#{prefix}instances", %w[one long-gone])

      expect(client.instances.size).to eq(1)
      expect(redis.smembers("#{prefix}instances")).to eq(['one'])
    end

    # The prune is a read followed by a write, and an instance that came back under the
    # same id in between would be taken out of the set by it: every RPC would then be
    # refused as if nothing were running, until it announced itself again.
    it 'keeps a member whose instance came back while it was being pruned' do
      redis.sadd("#{prefix}instances", 'flapping')
      # Absent when it is read, back by the time the member would be dropped.
      allow_any_instance_of(Redis).to receive(:hgetall).and_wrap_original do |original, *args| # rubocop:disable RSpec/AnyInstance
        original.call(*args).tap { redis.hset("#{prefix}instance:flapping", 'protocol_min', '1', 'protocol_max', '1') }
      end

      client.instances

      expect(redis.smembers("#{prefix}instances")).to eq(['flapping'])
    end

    # http://wa-1 is a prefix of http://wa-10, and taking the shorter one's token for the
    # longer one's blob is a 401 that the media path then reads as bytes that are gone.
    it 'matches the serving instance at a path boundary' do
      redis.hset("#{prefix}instance:one", 'advertise_url', 'http://wa-1:8080', 'media_token', 'token-one')
      redis.hset("#{prefix}instance:ten", 'advertise_url', 'http://wa-1:8080/connector/10', 'media_token', 'token-ten')
      redis.sadd("#{prefix}instances", %w[one ten])

      expect(client.media_token('http://wa-1:8080/connector/10/media/abc')).to eq('token-ten')
    end

    it 'falls back to a published token for a URL no instance advertises' do
      redis.hset("#{prefix}instance:one", 'advertise_url', 'http://wa-1:8080', 'media_token', 'token-one')
      redis.sadd("#{prefix}instances", 'one')

      expect(client.media_token('https://cdn.example.test/media/abc')).to eq('token-one')
    end

    it 'is incompatible when the connector moved past this protocol' do
      redis.hset("#{prefix}instance:one", 'protocol_min', '2', 'protocol_max', '3')
      redis.sadd("#{prefix}instances", 'one')

      expect(client).to be_available
      expect(client).not_to be_compatible
    end
  end
end
