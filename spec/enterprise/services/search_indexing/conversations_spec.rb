require 'rails_helper'

RSpec.describe SearchIndexing::Conversations do
  include_context 'with conversation search queue'

  before { allow(ChatwootApp).to receive(:advanced_search_allowed?).and_return(true) }

  it 'shares Alfred connections without changing existing Searchkick queue keys' do
    key = "searchkick:reindex_queue:#{search_index.name}"
    Redis::Alfred.with do |connection|
      connection.redis.lpush(key, [1, 2])
      connection.set(key, 'unrelated Alfred value')
      Searchkick.with_redis { |redis| expect(redis).to equal(connection.redis) }
    end

    expect(reindex_queue.reserve).to eq(%w[1 2])
    reindex_queue.push([3])
    Redis::Alfred.with do |connection|
      expect(connection.redis.lrange(key, 0, -1)).to eq(['3'])
      expect(connection.get(key)).to eq('unrelated Alfred value')
    end
  ensure
    Redis::Alfred.with { |connection| connection.del(key) }
  end

  it 'uses the native Searchkick drain to deduplicate a page and schedule bulk jobs' do
    reindex_queue.push([1, 1, 2])
    expect do
      Searchkick::ProcessQueueJob.perform_now(class_name: 'Conversation', index_name: search_index.name)
    end.to have_enqueued_job(Searchkick::ProcessBatchJob).with(class_name: 'Conversation', record_ids: %w[1 2], index_name: search_index.name)
    expect(reindex_queue.length).to eq(0)
  end

  it 'leaves IDs queued until operators provision the index' do
    reindex_queue.push([1])
    allow(search_index).to receive(:exists?).and_return(false)
    expect { ConversationSearchIndexJob.perform_now }.not_to have_enqueued_job(Searchkick::ProcessQueueJob)
    expect(reindex_queue.length).to eq(1)
  end

  it 'schedules the native drain when the index exists' do
    allow(search_index).to receive(:exists?).and_return(true)
    expect { ConversationSearchIndexJob.perform_now }.to have_enqueued_job(Searchkick::ProcessQueueJob).with(class_name: 'Conversation')
  end

  it 'only creates an index through explicit setup and leaves existing data intact' do
    allow(search_index).to receive(:exists?).and_return(false, true)
    allow(search_index).to receive(:index_options).and_return(mappings: described_class.name)
    allow(search_index).to receive(:create)
    2.times { described_class.setup! }
    expect(search_index).to have_received(:create).once.with(mappings: described_class.name)
  end
end
