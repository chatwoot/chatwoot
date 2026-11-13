require 'rails_helper'

RSpec.describe SearchIndexing::Search do
  include_context 'with search indexing Redis'

  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, role: :administrator) }
  let(:inbox) { create(:inbox, account: account, enable_auto_assignment: false) }
  let(:contact) { create(:contact, account: account, name: 'Renewal customer', email: 'renewal@example.com') }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact) }
  let(:client) { instance_double(OpenSearch::Client) }
  let(:state) { SearchIndexing::IndexState.find_by!(account_id: account.id, entity: 'conversations') }
  let(:response) { { 'timed_out' => false, '_shards' => { 'failed' => 0 }, 'hits' => { 'hits' => [{ '_id' => conversation.id.to_s }] } } }
  let(:service) { SearchService.new(current_user: user, current_account: account, params: { q: 'renewal' }, search_type: 'Conversation') }

  before do
    allow(ChatwootApp).to receive_messages(advanced_search_allowed?: true, chatwoot_cloud?: false)
    Current.account = account
    account.enable_features!('conversation_search_indexing', 'conversation_search')
    SearchIndexing::IndexState.create!(account_id: account.id, entity: 'conversations', epoch: SearchIndexing::Store.epoch,
                                       schema_version: SearchIndexing::ConversationDocument::SCHEMA_VERSION,
                                       run_token: SecureRandom.hex(16), status: 'ready', ready_at: Time.current)
    allow(Searchkick).to receive(:client).and_return(client)
    allow(client).to receive(:search).and_return(response)
  end

  after { Current.account = nil }

  it 'uses conversation candidates and searches email subjects without restricting an administrator to assigned inboxes' do
    expect(service.perform[:conversations]).to eq([conversation])
    expect(client).to have_received(:search) do |options|
      filters = options[:body][:query][:bool][:filter]
      expect(filters).to include({ term: { account_id: account.id } }, { term: { deleted: false } })
      expect(filters.last[:bool][:should]).to include(match_phrase: { 'mail_subject' => 'renewal' })
      expect(filters.any? { |filter| filter.key?(:terms) }).to be(false)
    end
  end

  it 'keeps contact search and its counts on SQL' do
    search = SearchService.new(current_user: user, current_account: account, params: { q: 'renewal' }, search_type: 'Contact')
    expect(search.perform[:contacts]).to eq([contact])
    expect(search.counts(['contacts'])).to eq('contacts' => 1)
    expect(client).not_to have_received(:search)
  end

  it 'preserves count and pagination contracts for email subject matches' do
    records = create_list(:conversation, 7, account: account, inbox: inbox, contact: contact,
                                            additional_attributes: { mail_subject: 'Shipping receipt' })
    response['hits']['hits'] = records.map { |record| { '_id' => record.id.to_s } }
    search = SearchService.new(current_user: user, current_account: account,
                               params: { q: 'shipping', per_page: 5, page: 2 }, search_type: 'Conversation')
    expect(search.perform[:conversations].map(&:id)).to eq(records.first(2).reverse.map(&:id))
    expect(search.counts(['conversations'])).to eq('conversations' => 7)
  end

  it 'does not expose another tenant or a conversation excluded by current role permissions' do
    role = create(:custom_role, account: account, permissions: ['conversation_unassigned_manage'])
    account.account_users.find_by!(user: user).update!(role: :agent, custom_role: role)
    create(:inbox_member, user: user, inbox: inbox)
    other = create(:conversation)
    restricted = create(:conversation, account: account, inbox: inbox, contact: contact, assignee: create(:user, account: account))
    conversation.update!(assignee: nil)
    response['hits']['hits'] = [conversation, restricted, other].map { |record| { '_id' => record.id.to_s } }
    expect(service.perform[:conversations]).to eq([conversation])
    expect(service.counts(['conversations'])).to eq({})
  end

  it 'keeps a valid empty response empty' do
    response['hits']['hits'] = []
    expect(service.perform[:conversations]).to be_empty
  end

  it 'falls back to SQL for transport failure, partial responses, and broad candidate sets' do
    allow(client).to receive(:search).and_raise(Faraday::ConnectionFailed)
    expect(service.perform[:conversations]).to eq([conversation])
    allow(client).to receive(:search).and_return(response.merge('timed_out' => true))
    expect(service.perform[:conversations]).to eq([conversation])
    response['hits']['hits'] = Array.new(1_001) { { '_id' => conversation.id.to_s } }
    allow(client).to receive(:search).and_return(response)
    expect(service.perform[:conversations]).to eq([conversation])
  end

  it 'falls back when the current generation is not ready' do
    state.update!(status: 'stale', ready_at: nil)
    expect(service.perform[:conversations]).to eq([conversation])
    expect(client).not_to have_received(:search)
  end

  it 'falls back for lagging contact dependency work' do
    SearchIndexing::Buffer.new(entity: 'contact_conversations', account_id: account.id).enqueue([contact.id])
    travel 121.seconds do
      expect(service.perform[:conversations]).to eq([conversation])
      expect(client).not_to have_received(:search)
    end
  end

  it 'falls back after a permanent live-write failure' do
    buffer = state.buffer
    buffer.enqueue([conversation.id])
    batch = buffer.claim
    buffer.acknowledge(batch, batch[:revisions].map { |id, revision| { id: id, revision: revision, state: 'failed' } })
    expect(service.perform[:conversations]).to eq([conversation])
    expect(client).not_to have_received(:search)
  end

  it 'leaves unsupported queries on SQL' do
    ['', 'ab', 'éclair', 'a_b', 'a%b', 'a\\b', 'a' * 257].each do |query|
      scope = account.conversations
      expect(described_class.new(account: account, query: query).narrow(scope)).to equal(scope)
    end
    expect(client).not_to have_received(:search)
  end

  it 'invalidates every ready tenant before recreating a missing physical index' do
    indices = instance_double(OpenSearch::API::Indices::IndicesClient, exists?: false, create: {})
    allow(client).to receive(:indices).and_return(indices)
    document = state.document
    document.ensure_index!(state.epoch)
    expect(state.reload).to have_attributes(status: 'stale', ready_at: nil)
    expect(service.perform[:conversations]).to eq([conversation])
    expect(client).not_to have_received(:search)
  end
end
