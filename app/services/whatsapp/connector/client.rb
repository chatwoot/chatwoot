# Talks to the connector over Redis: publishes commands, waits for RPC answers, and
# reads the registry that says whether anyone is listening.
#
# One client is one session. It uses its own connection pool rather than $alfred: that
# pool is namespaced under `alfred:`, and these keys belong to another process.
class Whatsapp::Connector::Client
  # A command stream is drained by its owner as fast as the session can execute; the cap
  # is a backstop against an owner that disappeared, not a working size.
  COMMAND_STREAM_MAXLEN = 1_000
  # How long an RPC waits before giving up. The deadline sent with the command is a
  # little shorter, so the connector stops working on it before the caller stops caring.
  RPC_TIMEOUT = 20
  DEADLINE_MARGIN = 2
  CHECKOUT_TIMEOUT = 5

  # Drops a set member whose instance hash is gone, checking again inside the same round
  # trip: an instance that re-registered under the same id between the read and this
  # would otherwise be taken back out of the set, and every RPC would be refused as if no
  # connector were running until it announced itself again.
  FORGET_INSTANCE = <<~LUA.freeze
    if redis.call('exists', KEYS[1]) == 0 then
      return redis.call('srem', KEYS[2], ARGV[1])
    end
    return 0
  LUA
  REPLY_TTL = 60
  # A connector heartbeat older than this means nobody is holding the sessions.
  INSTANCE_TTL = 60

  class << self
    def pool
      @pool ||= ConnectionPool.new(size: pool_size, timeout: CHECKOUT_TIMEOUT) do
        Redis.new(Redis::Config.app.merge(timeout: RPC_TIMEOUT + 5))
      end
    end

    # One connection per thread that can be sending: an RPC holds its connection in BLPOP
    # for as long as the connector takes to answer, so a pool smaller than the process's
    # own concurrency turns a slow connector into checkout timeouts on unrelated sends.
    def pool_size
      ENV.fetch('WHATSAPP_CONNECTOR_REDIS_POOL') do
        Sidekiq.server? ? ENV.fetch('SIDEKIQ_CONCURRENCY', 10) : ENV.fetch('RAILS_MAX_THREADS', 5)
      end.to_i
    end

    # Specs and the consumer's shard workers need their own connections.
    def reset_pool!
      @pool = nil
    end

    # Everything above this layer rescues Whatsapp::Session::Errors and nothing else, and
    # the jobs that retry do it on ProviderUnavailable, so a Redis that is down or a pool
    # with nothing free has to arrive as one of ours. Raw, both reach a group controller
    # or a send as a 500 and skip the retry that was meant for exactly this.
    def with_redis(&)
      pool.with(&)
    rescue ConnectionPool::TimeoutError => e
      raise Whatsapp::Session::Errors::ProviderUnavailable, "no connector connection available: #{e.message}"
    rescue Redis::BaseError => e
      raise Whatsapp::Session::Errors::ProviderUnavailable, "the connector transport failed: #{e.class}: #{e.message}"
    end
  end

  attr_reader :session_id

  def initialize(session_id)
    @session_id = session_id
  end

  # Fire and forget: the command is queued for the session's owner. Failures come back
  # later as a command.failed event.
  #
  # Nobody here is waiting to give up on it, so whatever ceiling it carries is the only
  # one it gets, and without either the command runs for as long as it takes while the
  # session's executor -- which takes one command at a time -- holds everything behind it.
  #
  # `timeout` is how long the command is still worth running at all, counted from now:
  # past it the connector refuses it unrun. `max_runtime` is how long it may take once
  # started, and says nothing about arriving late. A command that must be carried out
  # whenever it arrives takes the second alone.
  def publish(payload, idempotency_key: nil, timeout: nil, max_runtime: nil)
    ensure_readable!
    command = build(payload, idempotency_key: idempotency_key, timeout: timeout, max_runtime: max_runtime)
    write(command_stream, command)
    command.id
  end

  # Queues the command and waits for the answer the owner pushes back.
  def call(payload, timeout: RPC_TIMEOUT, idempotency_key: nil)
    ensure_available!
    command = build(payload, idempotency_key: idempotency_key, reply_to: true, timeout: timeout - DEADLINE_MARGIN)
    write(command_stream, command)
    await(command, timeout)
  end

  # Commands that go to the fleet rather than to one session's owner: a wake, a ping, and
  # the teardown of a session nobody is running.
  #
  # Guarded like `publish` and for the same reason, which used to be covered by accident:
  # the only caller was `connect`, whose `call` right after raises before anything reads
  # the wake. A fire-and-forget command written here is the whole of what the caller does,
  # and a connector that is up and speaks another protocol consumes the frame and drops it
  # while the caller is told it was queued -- which for a teardown is a device left listed
  # on somebody's phone with nothing anywhere saying so.
  def control(payload, timeout: RPC_TIMEOUT, max_runtime: nil)
    ensure_readable!
    rpc = model::Commands.rpc?(payload.class.wire_type)
    command = build(payload, reply_to: rpc, timeout: (timeout - DEADLINE_MARGIN if rpc), max_runtime: max_runtime)
    write(Whatsapp::Connector.key('control'), command)
    return command.id unless command.reply_to

    await(command, timeout)
  end

  # Live connector instances and what they advertise (version, protocol range, media
  # endpoint). Their hashes expire on their own, so what is here is what is alive.
  #
  # The set does not expire with them, and an instance that crashed or came back under a
  # new id would otherwise stay a member for good: every send would then pay an extra
  # round trip for it, for as long as the installation lives. Members whose hash is gone
  # are dropped as they are found.
  def instances
    self.class.with_redis do |redis|
      expired = []
      live = redis.smembers(Whatsapp::Connector.key('instances')).filter_map do |id|
        instance = redis.hgetall(Whatsapp::Connector.key('instance', id)).presence
        expired << id if instance.nil?
        instance
      end
      forget(redis, expired)
      live
    end
  end

  def available?
    instances.any?
  end

  # Both sides serve a range of protocol majors; they can talk when the ranges overlap.
  def compatible?
    instances.any? { |instance| speaks_our_protocol?(instance) }
  end

  # The bearer token a blob URL is served with. Each instance publishes its own and only
  # accepts that one, and a blob lives on the instance that downloaded it, so the token
  # has to be picked by the URL rather than by whichever instance the registry lists
  # first. Falling back to any of them covers a URL served from somewhere else entirely.
  def media_token(url)
    live = instances
    # The longest base wins where several match, the way any prefix route resolves: one
    # instance can be advertised under another's host with a path of its own.
    owner = live.select { |instance| serves?(instance['advertise_url'], url) }
                .max_by { |instance| instance['advertise_url'].to_s.length }
    (owner || live.first)&.dig('media_token').presence
  end

  private

  # Resolved when they are called, never held in a constant: a constant captured at load
  # time keeps the namespace from before the last reload, and its autoloaded children are
  # gone from it by then.
  def model = Whatsapp::Session::Model
  def errors = Whatsapp::Session::Errors

  def command_stream
    Whatsapp::Connector.key('cmd', session_id)
  end

  # `timeout` is the whole budget the command declares, already net of any margin its
  # caller wanted: an RPC hands over less than it will wait, a published command hands
  # over what the command is worth, and either can hand over nothing. It becomes the
  # frame's `deadline`, an instant, which is why the clock starts here rather than when
  # the owner picks the command up.
  #
  # `max_runtime` is the other ceiling, and both are seconds. It becomes a duration on the
  # frame and the connector starts counting it when the work does, so queueing time never
  # eats into it: that is what lets a command be bounded without also being droppable.
  def build(payload, idempotency_key: nil, reply_to: false, timeout: nil, max_runtime: nil)
    id = SecureRandom.uuid
    now = (Time.current.to_f * 1000).round
    attributes = { id: id, sid: session_id, ts: now, idempotency_key: idempotency_key }
    attributes[:reply_to] = reply_key(id) if reply_to
    attributes[:deadline] = now + (timeout * 1000).round if timeout
    attributes[:max_runtime_ms] = (max_runtime * 1000).round if max_runtime
    model::Command.build(payload, **attributes)
  end

  def reply_key(command_id)
    Whatsapp::Connector.key('reply', command_id)
  end

  def write(stream, command)
    fields = command.to_frame.transform_values { |value| value.is_a?(String) ? value : value.to_json }
    self.class.with_redis do |redis|
      redis.xadd(stream, fields, maxlen: COMMAND_STREAM_MAXLEN, approximate: true)
    end
  end

  def await(command, timeout)
    raw = self.class.with_redis { |redis| redis.blpop(command.reply_to, timeout: timeout) }
    raise errors::Timeout, "no answer to #{command.type} within #{timeout}s" if raw.nil?

    reply = JSON.parse(raw.last)
    raise error_for(reply) unless reply['ok']

    reply['result']
  rescue JSON::ParserError => e
    raise errors::Internal, "malformed reply to #{command.type}: #{e.message}"
  end

  def error_for(reply)
    error = reply['error'] || {}
    errors.build(error['code'], error['message'])
  end

  def forget(redis, ids)
    ids.each do |id|
      redis.eval(FORGET_INSTANCE,
                 keys: [Whatsapp::Connector.key('instance', id), Whatsapp::Connector.key('instances')], argv: [id])
    end
  end

  # At a path boundary, not by bare prefix: http://wa-1 is a prefix of http://wa-10, and
  # taking the shorter one's token for the longer one's blob is a 401 the media path then
  # reads as bytes that are gone.
  def serves?(advertised, url)
    base = advertised.presence&.chomp('/')
    return false if base.nil?

    url = url.to_s
    url == base || url.start_with?("#{base}/")
  end

  def speaks_our_protocol?(instance)
    min = instance['protocol_min'].to_i
    max = instance['protocol_max'].to_i
    max.positive? && Whatsapp::Session::PROTOCOL_VERSION.between?(min, max)
  end

  # A command sent with nobody listening would sit in the stream until it expired, and
  # the agent would watch a message hang as "sending" for the whole deadline. A connector
  # that is running but has moved past this protocol is the same thing with a step in
  # between: it reads the frame, does not recognize the version, and drops it. Refusing
  # here is what turns both into an error the agent can see.
  def ensure_available!
    raise errors::ProviderUnavailable, 'no whatsapp connector is running' if instances.empty?

    ensure_readable!
  end

  # What a fire-and-forget command needs, which is less than an answer needs: nobody has
  # to be listening right now, because the stream holds the frame until a connector comes
  # up and reads it. What must not happen is a connector that is up and speaks another
  # protocol, because it consumes the frame and drops it while the caller is told it was
  # queued. A logout or a delete that is quietly discarded leaves the session paired.
  def ensure_readable!
    live = instances
    return if live.empty? || live.any? { |instance| speaks_our_protocol?(instance) }

    raise errors::ProviderUnavailable, "no whatsapp connector speaks protocol #{Whatsapp::Session::PROTOCOL_VERSION}"
  end
end
