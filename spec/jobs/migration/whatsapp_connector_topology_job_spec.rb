require 'rails_helper'

RSpec.describe Migration::WhatsappConnectorTopologyJob, :redis_streams do
  let(:prefix) { "watest#{SecureRandom.hex(4)}:" }
  let(:redis) { Redis.new(Redis::Config.app) }
  let(:topology) { redis.get("#{prefix}consumers:topology") }

  around do |example|
    with_modified_env(WHATSAPP_CONNECTOR_REDIS_PREFIX: prefix) { example.run }
    keys = redis.keys("#{prefix}*")
    redis.del(*keys) if keys.any?
  end

  # An installation that re-sharded before the consumers started recording the topology
  # still has its retired streams, and nothing else says how far up they go.
  it 'records the topology the existing streams reach, gaps included' do
    redis.xadd("#{prefix}events:0", { 'v' => '1' })
    redis.xadd("#{prefix}events:11", { 'v' => '1' })

    described_class.perform_now

    expect(topology).to eq('12')
  end

  # A consumer of the previous release may have recorded a smaller topology than the
  # streams show, or a larger one than survives: the record only ever grows.
  it 'keeps the largest of the record and the streams' do
    redis.set("#{prefix}consumers:topology", 16)
    redis.xadd("#{prefix}events:3", { 'v' => '1' })

    described_class.perform_now

    expect(topology).to eq('16')
  end

  # Lease keys share the prefix, and anything else can sit under it; only a stream says a
  # topology reached that number.
  it 'counts only event streams' do
    redis.xadd("#{prefix}events:1", { 'v' => '1' })
    redis.set("#{prefix}events:40:lease", 'someone')
    redis.set("#{prefix}events:30", 'not a stream')
    redis.xadd("#{prefix}events:abc", { 'v' => '1' })

    described_class.perform_now

    expect(topology).to eq('2')
  end

  it 'writes nothing on an installation that never ran a connector' do
    described_class.perform_now

    expect(redis.keys("#{prefix}*")).to be_empty
  end
end
