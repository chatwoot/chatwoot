require 'rails_helper'

# rubocop:disable RSpec/DescribeClass -- the subject is the Listener patch in
# config/initializers/actioncable.rb, exercised through the adapter against a real Redis.
describe 'Action Cable Redis listener recovery', :redis_streams do
  let(:server) do
    # A configuration of its own: the default is the class-level one, shared with ActionCable.server.
    ActionCable::Server::Base.new(config: ActionCable::Server::Configuration.new).tap do |cable_server|
      cable_server.config.cable = {
        adapter: 'redis',
        url: Redis::Config.app[:url],
        password: Redis::Config.app[:password],
        channel_prefix: "spec_cable_listener_#{SecureRandom.hex(4)}",
        # A budget of two retries: stock Rails gives up on the third consecutive failure.
        reconnect_attempts: [0, 0.05]
      }
      cable_server.config.logger = Logger.new(nil)
    end
  end
  let(:adapter) { ActionCable::SubscriptionAdapter::Redis.new(server) }
  let(:events) { Queue.new }
  let(:attempts) { Queue.new }
  let(:outage) { { on: false } }
  let(:control) { Redis.new(Redis::Config.app) }

  before do
    allow(adapter).to receive(:redis_connection_for_subscriptions).and_wrap_original do |original|
      attempts << :attempt
      raise Redis::CannotConnectError, 'simulated outage' if outage[:on]

      original.call
    end
  end

  after do
    outage[:on] = false
    adapter.shutdown
    server.event_loop.stop
    control.close
  end

  # Returns the message callback, which is what unsubscribe takes to drop that subscriber.
  def subscribe(channel, name)
    on_message = ->(message) { events << [name, message] }
    adapter.subscribe(channel, on_message, -> { events << [name, :confirmed] })
    on_message
  end

  # Waits for `count` failed connection attempts. Past the budget of two retries stock Rails makes no more.
  def wait_for_failed_attempts(count)
    count.times { expect(attempts.pop(timeout: 5)).to eq(:attempt) }
  end

  # Earlier examples in this process leave connections under the same name, so drop them all.
  def kill_listener_connection
    listeners = control.call('CLIENT', 'LIST').lines.grep(/ name=ActionCable-PID-#{Process.pid} /)
    listeners.each { |line| control.call('CLIENT', 'KILL', 'ID', line[/\bid=(\d+)/, 1]) }
  end

  # Broadcasts sent before the listener has resubscribed are lost, so publish until one lands.
  def broadcast_until_delivered(channel)
    20.times do |i|
      adapter.broadcast(channel, "ping-#{i}")
      event = events.pop(timeout: 0.25)
      return event if event
    end
    nil
  end

  it 'asks every connected client to reconnect once the listener is back after losing Redis' do
    closed = Queue.new
    connection = Struct.new(:name, :on_close) { def close(**options) = on_close.call(self, options) }
    %i[first second].each do |name|
      stream = subscribe("room-#{name}", name)
      expect(events.pop(timeout: 5)).to eq([name, :confirmed])
      # Like a real connection, closing stops its streams, which reaches back into the listener, and
      # the close handshake can drop it from the server's list while the others are still being closed.
      server.add_connection(connection.new(name, lambda do |closing, options|
        adapter.unsubscribe("room-#{name}", stream)
        server.remove_connection(closing)
        closed << [closing.name, options[:reconnect]]
      end))
    end
    # The first connection at boot follows no outage, so nobody missed anything.
    expect(closed.pop(timeout: 0.5)).to be_nil

    kill_listener_connection

    expect(Array.new(2) { closed.pop(timeout: 5) }).to contain_exactly([:first, true], [:second, true])
  end

  it 'confirms a subscription made while Redis stays unreachable past the retry budget' do
    outage[:on] = true
    subscribe('room', :first)
    wait_for_failed_attempts(3)
    outage[:on] = false

    expect(events.pop(timeout: 5)).to eq([:first, :confirmed])
    adapter.broadcast('room', 'hello')
    expect(events.pop(timeout: 5)).to eq([:first, 'hello'])
  end

  it 'delivers again to a channel subscribed before the connection dropped past the retry budget' do
    subscribe('room', :first)
    expect(events.pop(timeout: 5)).to eq([:first, :confirmed])
    attempts.clear

    outage[:on] = true
    kill_listener_connection
    wait_for_failed_attempts(2)
    outage[:on] = false

    expect(broadcast_until_delivered('room')).to match([:first, /\Aping-\d+\z/])
  end

  it 'keeps waiting the last configured interval between retries past the budget' do
    outage[:on] = true
    subscribe('room', :first)
    wait_for_failed_attempts(3)
    attempts.clear
    # 0.05s apart, a second holds about 20 attempts; an unpaced loop makes thousands.
    sleep 1

    expect(attempts.size).to be_between(5, 30)
  end

  it 'stops retrying when the server shuts down during the outage' do
    outage[:on] = true
    subscribe('room', :first)
    wait_for_failed_attempts(3)

    expect(Thread.new { adapter.shutdown }.join(2)).to be_truthy
  end

  it 'confirms a channel that rejoins after a drop that caught a departed confirmation still pending' do
    swallowed = { done: false }
    allow(adapter).to receive(:redis_connection_for_subscriptions).and_wrap_original do |original|
      attempts << :attempt
      raise Redis::CannotConnectError, 'simulated outage' if outage[:on]

      original.call.tap do |connection|
        # The first SUBSCRIBE for the room never reaches Redis, so its confirmation is still pending
        # when the subscriber leaves, as when it leaves before the reply is read.
        connection.singleton_class.prepend(Module.new do
          define_method(:subscribe) do |*channels, &block|
            if block.nil? && !swallowed[:done] && channels.first.to_s.end_with?(':room')
              swallowed[:done] = true
              next nil
            end
            super(*channels, &block)
          end
        end)
      end
    end
    subscribe('other', :ready)
    expect(events.pop(timeout: 5)).to eq([:ready, :confirmed])
    adapter.unsubscribe('room', subscribe('room', :left))
    attempts.clear

    outage[:on] = true
    kill_listener_connection
    wait_for_failed_attempts(1)
    outage[:on] = false
    expect(broadcast_until_delivered('other')).to match([:ready, /\Aping-\d+\z/])
    subscribe('room', :rejoined)

    expect(events.pop(timeout: 5)).to eq([:rejoined, :confirmed])
  end

  it 'releases the confirmations of subscribers that leave while Redis is unreachable' do
    outage[:on] = true
    50.times { |i| adapter.unsubscribe("room-#{i}", subscribe("room-#{i}", :left)) }
    wait_for_failed_attempts(3)

    expect(adapter.send(:listener).instance_variable_get(:@subscribe_callbacks)).to be_empty
  end

  it 'confirms a channel re-added during the outage, not the subscription that left' do
    outage[:on] = true
    left = subscribe('room', :left)
    wait_for_failed_attempts(3)
    adapter.unsubscribe('room', left)
    subscribe('room', :rejoined)
    outage[:on] = false

    expect(events.pop(timeout: 5)).to eq([:rejoined, :confirmed])
    adapter.broadcast('room', 'hello')
    expect(events.pop(timeout: 5)).to eq([:rejoined, 'hello'])
    expect(events.pop(timeout: 0.5)).to be_nil
  end
end
# rubocop:enable RSpec/DescribeClass
