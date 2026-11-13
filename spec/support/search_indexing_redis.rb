RSpec.shared_context 'with search indexing Redis' do
  let(:indexing_redis) do
    Redis::Namespace.new("search_indexing_spec:#{SecureRandom.hex(8)}", redis: Redis.new(**Redis::Config.app))
  end

  before do
    allow(Redis::Alfred).to receive(:with).and_yield(indexing_redis)
    allow(Redis::Alfred).to receive(:exists?) { |key| indexing_redis.exists?(key) }
    allow(Redis::Alfred).to receive(:hget) { |key, field| indexing_redis.hget(key, field) }
  end

  after do
    keys = indexing_redis.keys('*')
    indexing_redis.del(*keys) if keys.any?
    indexing_redis.redis.close
  end
end
