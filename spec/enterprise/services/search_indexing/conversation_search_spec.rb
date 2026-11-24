require 'rails_helper'

RSpec.describe SearchIndexing::ConversationSearch do
  subject(:search) { described_class.new(account, query, [42]) }

  let(:account) { create(:account) }
  let(:query) { 'example' }
  let(:client) { instance_double(OpenSearch::Client) }
  let(:response) do
    { '_shards' => { 'failed' => 0 }, 'hits' => { 'total' => { 'value' => 1, 'relation' => 'eq' }, 'hits' => [{ '_id' => '123' }] } }
  end

  before do
    allow(ChatwootApp).to receive(:advanced_search_allowed?).and_return(true)
    account.enable_features!('advanced_search_conversations')
    allow(Searchkick).to receive(:client).and_return(client)
    allow(client).to receive(:search).and_return(response)
  end

  it 'requests complete candidates scoped to the account and accessible inboxes' do
    expect(search.ids).to eq([123])
    expect(client).to have_received(:search).with(
      index: Conversation.search_index.name,
      body: hash_including(query: { bool: {
                             filter: [{ term: { account_id: account.id } }, { terms: { inbox_id: [42] } }],
                             must: [{ multi_match: { query: query, fields: described_class::FIELDS, type: 'phrase' } }]
                           } })
    )
  end

  it 'keeps a valid empty result empty' do
    response['hits'] = { 'total' => { 'value' => 0, 'relation' => 'eq' }, 'hits' => [] }
    expect(search.ids).to eq([])
  end

  it 'uses OpenSearch without any account readiness metadata' do
    expect(account.internal_attributes).to eq({})
    expect(search.ids).to eq([123])
  end

  it 'falls back when the account feature is disabled' do
    account.disable_features!('advanced_search_conversations')
    expect(search.ids).to be_nil
    expect(client).not_to have_received(:search)
  end

  it 'falls back when OpenSearch is not configured' do
    allow(ChatwootApp).to receive(:advanced_search_allowed?).and_return(false)
    expect(search.ids).to be_nil
    expect(client).not_to have_received(:search)
  end

  ['ab', 'résumé', 'a_b', 'a%b', 'a\\b', 'a' * 257].each do |unsupported|
    it "uses SQL for unsupported query #{unsupported.first(12).inspect}" do
      expect(described_class.new(account, unsupported, [42]).ids).to be_nil
      expect(client).not_to have_received(:search)
    end
  end

  it 'falls back rather than truncating broad matches' do
    response['hits']['total']['value'] = described_class::CANDIDATE_LIMIT + 1
    expect(search.ids).to be_nil
  end

  it 'rejects incomplete or timed out responses' do
    response['_shards']['failed'] = 1
    expect(search.ids).to be_nil
    response['_shards']['failed'] = 0
    response['timed_out'] = true
    expect(search.ids).to be_nil
  end

  it 'falls back on transport failure but exposes invalid query errors' do
    allow(client).to receive(:search).and_raise(Faraday::ConnectionFailed)
    expect(search.ids).to be_nil
    allow(client).to receive(:search).and_raise(OpenSearch::Transport::Transport::Errors::BadRequest)
    expect { search.ids }.to raise_error(OpenSearch::Transport::Transport::Errors::BadRequest)
  end
end
