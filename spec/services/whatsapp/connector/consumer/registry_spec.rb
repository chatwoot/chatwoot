require 'rails_helper'

RSpec.describe Whatsapp::Connector::Consumer::Registry, :redis_streams do
  subject(:registry) { described_class.new(redis, 'consumer-1') }

  let(:prefix) { "watest#{SecureRandom.hex(4)}:" }
  let(:redis) { Redis.new(Redis::Config.app) }
  let(:peer) { described_class.new(redis, 'consumer-2') }

  around do |example|
    with_modified_env(WHATSAPP_CONNECTOR_REDIS_PREFIX: prefix) { example.run }
    keys = redis.keys("#{prefix}*")
    redis.del(*keys) if keys.any?
  end

  it 'counts the shards every live consumer holds' do
    registry.announce([0, 1])
    peer.announce([2])

    expect(registry.held_counts).to contain_exactly(2, 1)
  end

  # Every consumer asks this on every tick, against the Redis the whole installation
  # shares. Walking the keyspace to answer it cost a production Redis 72% of its CPU,
  # with 94 thousand keys of which a handful were heartbeats.
  it 'answers without walking the keyspace' do
    registry.announce([0])
    peer.announce([1])
    allow_any_instance_of(Redis).to receive(:scan).and_raise('walked the keyspace') # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(Redis).to receive(:keys).and_raise('walked the keyspace') # rubocop:disable RSpec/AnyInstance

    expect(registry.held_counts).to contain_exactly(1, 1)
  end

  # A process killed without a shutdown never withdraws. Its heartbeat lapsing is the
  # only sign it is gone, and counting it after that leaves its share unclaimed.
  it 'stops counting a consumer whose heartbeat lapsed' do
    registry.announce([0])
    peer.announce([1, 2])
    redis.del("#{prefix}consumer:consumer-2")

    expect(registry.held_counts).to eq([1])
    expect(redis.sismember("#{prefix}consumers", 'consumer-2')).to be(false)
  end

  it 'stops counting a consumer that withdrew' do
    registry.announce([0])
    peer.announce([1])

    peer.withdraw

    expect(registry.held_counts).to eq([1])
  end

  # During a rolling deploy the previous version is still running, and it finds its peers
  # by their heartbeat keys. A heartbeat it cannot see makes it hold on to shards this
  # version is waiting for.
  it 'keeps the heartbeat where the previous version looks for it' do
    registry.announce([3, 1])

    heartbeat = redis.get("#{prefix}consumer:consumer-1")
    expect(JSON.parse(heartbeat)['shards']).to eq([1, 3])
    expect(redis.ttl("#{prefix}consumer:consumer-1")).to be_between(1, described_class::TTL)
  end
end
