RSpec.shared_context 'with conversation search queue' do
  let(:search_index) { Searchkick::Index.new("conversation_search_spec_#{SecureRandom.hex(8)}", Conversation.searchkick_options) }
  let(:reindex_queue) { search_index.reindex_queue }

  around do |example|
    previous_redis = Searchkick.redis
    Searchkick.redis = Redis.new(**Redis::Config.app)
    example.run
  ensure
    reindex_queue.clear
    Searchkick.redis.close
    Searchkick.redis = previous_redis
  end

  before do
    allow(Conversation).to receive_messages(search_index: search_index, searchkick_index: search_index)
  end
end
