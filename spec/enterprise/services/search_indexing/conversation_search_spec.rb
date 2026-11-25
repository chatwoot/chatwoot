require 'rails_helper'

RSpec.describe SearchIndexing::ConversationSearch do
  subject(:result) { search.perform(cursor: cursor) }

  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:scope) { account.conversations }
  let(:cursor) { nil }
  let(:search) do
    described_class.new(account: account, user: user, query: query, scope: scope)
  end
  let(:query) { instance_double(SearchIndexing::ConversationSearchQuery, body: { collapse: { field: 'conversation_id' } }) }
  let(:client) { instance_double(OpenSearch::Client) }
  let(:response) { { '_shards' => { 'failed' => 0 }, 'hits' => { 'hits' => hits } } }
  let(:hits) { [{ 'fields' => { 'conversation_id' => [conversation.id] } }] }

  before do
    create(:inbox_member, inbox: inbox, user: user)
    allow(SearchIndexing::ConversationSearchQuery).to receive(:new).and_return(query)
    allow(Searchkick).to receive(:client).and_return(client)
    allow(client).to receive(:search).and_return(response)
    # Message's Searchkick methods are installed only when OpenSearch is configured at boot.
    without_partial_double_verification do
      allow(Message).to receive(:search_index).and_return(Searchkick::Index.new('messages_test'))
    end
  end

  it 'queries both indexes and loads the ranked conversations' do
    expect(result).to eq(conversations: [conversation], next_cursor: nil, has_more: false)
    expect(client).to have_received(:search).with(index: [Conversation.search_index.name, 'messages_test'],
                                                  search_type: 'dfs_query_then_fetch', body: hash_including(from: 0, size: 500))
  end

  it 'preserves engine ranking instead of sorting by conversation creation or ID' do
    newer = create(:conversation, account: account, inbox: inbox)
    hits << { 'fields' => { 'conversation_id' => [newer.id] } }
    expect(result[:conversations]).to eq([conversation, newer])
  end

  it 'rechecks live tenant and inbox permissions, including stale documents' do
    inaccessible = create(:conversation, account: account)
    foreign = create(:conversation)
    [inaccessible.id, foreign.id, 0].each { |id| hits.unshift('fields' => { 'conversation_id' => [id] }) }
    expect(result[:conversations]).to eq([conversation])
  end

  it 'rechecks custom-role assignment and participation' do
    role = create(:custom_role, account: account, permissions: ['conversation_participating_manage'])
    account.account_users.find_by!(user: user).update!(custom_role: role)
    conversation.update!(assignee: nil)
    expect(result[:conversations]).to be_empty
    create(:conversation_participant, account: account, conversation: conversation, user: user)
    expect(search.perform[:conversations]).to eq([conversation])
  end

  it 'fills a page across inaccessible candidate batches without exposing an empty intermediate page' do
    stub_const("#{described_class}::BATCH_SIZE", 2)
    inaccessible = create(:conversation, account: account)
    denied = { 'fields' => { 'conversation_id' => [inaccessible.id] } }
    allow(client).to receive(:search).and_return(response.merge('hits' => { 'hits' => [denied, denied] }), response)
    expect(result[:conversations]).to eq([conversation])
    expect(client).to have_received(:search).with(hash_including(body: hash_including(from: 2)))
  end

  it 'returns 25 records and continues at the next accessible ranked conversation' do
    rows = create_list(:conversation, 25, account: account, inbox: inbox)
    hits.concat(rows.map { |row| { 'fields' => { 'conversation_id' => [row.id] } } })
    expect(result[:conversations].size).to eq(25)
    expect(result.slice(:next_cursor, :has_more)).to eq(next_cursor: '25', has_more: true)
    allow(client).to receive(:search).and_return(response.merge('hits' => { 'hits' => [hits.last] }))
    expect(search.perform(cursor: '25')[:conversations]).to eq([rows.last])
  end

  context 'when at the end of the result window' do
    let(:cursor) { '9999' }

    it 'caps requests at 10000 and returns no further cursor' do
      expect(result).to eq(conversations: [conversation], next_cursor: nil, has_more: false)
      expect(client).to have_received(:search).with(hash_including(body: hash_including(from: 9999, size: 1)))
      expect(search.perform(cursor: '10000')[:conversations]).to be_empty
      expect(client).to have_received(:search).once
    end
  end

  it 'rejects failed or timed-out shards instead of reporting incomplete results' do
    response['timed_out'] = true
    expect { result }.to raise_error(Searchkick::Error)
    response['timed_out'] = false
    response['_shards']['failed'] = 1
    expect { search.perform }.to raise_error(Searchkick::Error)
  end

  it 'rejects invalid cursors before querying' do
    expect { search.perform(cursor: '-1') }.to raise_error(ArgumentError)
    expect(client).not_to have_received(:search)
  end
end
