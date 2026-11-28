RSpec.shared_context 'with conversation search queue' do
  let(:search_index) { Searchkick::Index.new("conversation_search_spec_#{SecureRandom.hex(8)}", Conversation.searchkick_options) }
  let(:reindex_queue) { search_index.reindex_queue }

  let(:search_redis_pool) do
    ConnectionPool.new(size: 1, timeout: 1) do
      Redis::Namespace.new('alfred', redis: Redis.new(**Redis::Config.app), deprecations: true)
    end
  end

  after do
    reindex_queue.clear
    search_redis_pool.shutdown { |connection| connection.redis.close }
  end

  before do
    allow(Redis::Alfred).to receive(:with) { |&block| search_redis_pool.with(&block) }
    allow(Conversation).to receive_messages(search_index: search_index, searchkick_index: search_index)
  end
end
