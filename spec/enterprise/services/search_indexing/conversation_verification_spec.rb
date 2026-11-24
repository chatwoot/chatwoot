require 'rails_helper'

RSpec.describe SearchIndexing::ConversationVerification do
  include_context 'with conversation search queue'

  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account).reload }
  let(:client) { instance_double(OpenSearch::Client) }
  let(:scan) { instance_double(SearchIndexing::IndexedConversations) }
  let(:response) do
    { '_shards' => { 'failed' => 0 }, 'hits' => { 'hits' => [{ '_id' => conversation.id.to_s, '_source' => conversation.search_data.as_json }] } }
  end
  let(:identity) { { 'name' => search_index.name, 'uuid' => 'one' } }

  before do
    allow(ChatwootApp).to receive(:advanced_search_allowed?).and_return(true)
    account.enable_features!('advanced_search_conversations')
    allow(Searchkick).to receive(:client).and_return(client)
    allow(SearchIndexing::IndexVerification).to receive(:identity).and_return(identity)
    allow(search_index).to receive(:refresh)
    allow(SearchIndexing::IndexedConversations).to receive(:new).with(account.id).and_return(scan)
    allow(scan).to receive(:each_batch)
    allow(Searchkick::ProcessBatchJob).to receive(:perform_now)
    allow(client).to receive(:search).and_return(response)
  end

  it 'records coverage only after a clean scan with explicit activation' do
    expect(described_class.new(account).perform).to include(clean: true, verified: false)
    expect(SearchIndexing::IndexVerification.ready?(account.reload)).to be(false)
    expect(described_class.new(account).perform(activate: true)).to include(clean: true, verified: true)
    expect(SearchIndexing::IndexVerification.ready?(account.reload)).to be(true)
  end

  it 'repairs missing documents but requires a fresh verification pass' do
    response['hits']['hits'] = []
    expect(described_class.new(account).perform(activate: true)).to include(missing: 1, verified: false)
    expect(Searchkick::ProcessBatchJob).to have_received(:perform_now).with(
      class_name: 'Conversation', record_ids: [conversation.id.to_s], index_name: search_index.name
    )
  end

  it 'detects stale fields even when document counts match' do
    source = conversation.search_data.as_json.merge('mail_subject' => 'old')
    response['hits']['hits'].first['_source'] = source
    expect(described_class.new(account).perform(activate: true)).to include(stale: 1, verified: false)
  end

  it 'invalidates earlier verification before attempting a repair that may fail' do
    described_class.new(account).perform(activate: true)
    response['hits']['hits'] = []
    allow(Searchkick::ProcessBatchJob).to receive(:perform_now).and_raise(Searchkick::Error, 'bulk write failed')

    expect { described_class.new(account).perform(activate: true) }.to raise_error(Searchkick::Error, 'bulk write failed')
    expect(SearchIndexing::IndexVerification.ready?(account.reload)).to be(false)
  end

  it 'removes orphan IDs through the native bulk processor' do
    allow(scan).to receive(:each_batch).and_yield([{ '_id' => '99999999' }])
    expect(described_class.new(account).perform(activate: true)).to include(orphaned: 1, verified: false)
    expect(Searchkick::ProcessBatchJob).to have_received(:perform_now).with(
      class_name: 'Conversation', record_ids: ['99999999'], index_name: search_index.name
    )
  end

  it 'scopes source checks to the account as well as record IDs' do
    described_class.new(account).perform
    expect(client).to have_received(:search).with(
      index: search_index.name,
      body: { size: 1, query: { bool: { filter: [{ term: { account_id: account.id } }, { ids: { values: [conversation.id] } }] } } }
    )
  end

  it 'rejects partial source checks instead of treating them as missing documents' do
    response['_shards']['failed'] = 1
    expect { described_class.new(account).perform(activate: true) }.to raise_error(Searchkick::Error)
    expect(Searchkick::ProcessBatchJob).not_to have_received(:perform_now)
  end

  it 'does not verify an incomplete response' do
    allow(scan).to receive(:each_batch).and_raise(Searchkick::Error, 'partial response')
    expect { described_class.new(account).perform(activate: true) }.to raise_error(Searchkick::Error)
    expect(SearchIndexing::IndexVerification.ready?(account.reload)).to be(false)
  end
end
