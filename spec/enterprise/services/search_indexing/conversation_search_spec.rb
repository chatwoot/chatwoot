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
  let(:query) do
    instance_double(SearchIndexing::ConversationSearchQuery, body: { collapse: { field: 'conversation_id' } }, message_counts_body: { size: 0 })
  end
  let(:client) { instance_double(OpenSearch::Client) }
  let(:response) { { '_shards' => { 'failed' => 0 }, 'hits' => { 'hits' => hits } } }
  let(:hits) { [{ '_score' => 10, 'fields' => { 'conversation_id' => [conversation.id] } }] }
  let(:counts) { [] }
  let(:count_response) { { '_shards' => { 'failed' => 0 }, 'aggregations' => { 'conversations' => { 'buckets' => counts } } } }

  before do
    create(:inbox_member, inbox: inbox, user: user)
    allow(SearchIndexing::ConversationSearchQuery).to receive(:new).and_return(query)
    allow(Searchkick).to receive(:client).and_return(client)
    allow(client).to receive(:search).and_return(response)
    allow(client).to receive(:search).with(index: 'messages_test', body: { size: 0 }).and_return(count_response)
    # Message's Searchkick methods are installed only when OpenSearch is configured at boot.
    without_partial_double_verification do
      allow(Message).to receive(:search_index).and_return(Searchkick::Index.new('messages_test'))
    end
  end

  it 'selects the first 10000 relevance candidates from both indexes and counts their matching messages' do
    expect(result).to eq(conversations: [conversation], next_cursor: nil, has_more: false)
    expect(client).to have_received(:search).with(index: [Conversation.search_index.name, 'messages_test'],
                                                  search_type: 'dfs_query_then_fetch', body: hash_including(size: 10_000))
    expect(query).to have_received(:message_counts_body).with([conversation.id])
  end

  it 'preserves relevance order when conversations have zero or one matching message' do
    newer = create(:conversation, account: account, inbox: inbox)
    hits << { '_score' => 9.9, 'fields' => { 'conversation_id' => [newer.id] } }
    counts << { 'key' => newer.id, 'doc_count' => 1 }
    expect(result[:conversations]).to eq([conversation, newer])
  end

  it 'promotes a slightly less relevant conversation with multiple matching messages' do
    repeated = create(:conversation, account: account, inbox: inbox)
    hits << { '_score' => 9.9, 'fields' => { 'conversation_id' => [repeated.id] } }
    counts << { 'key' => repeated.id, 'doc_count' => 2 }
    expect(result[:conversations]).to eq([repeated, conversation])
  end

  it 'caps the bonus so many weak matches cannot overwhelm a substantially better match' do
    repeated = create(:conversation, account: account, inbox: inbox)
    hits << { '_score' => 6, 'fields' => { 'conversation_id' => [repeated.id] } }
    counts << { 'key' => repeated.id, 'doc_count' => 1000 }
    expect(result[:conversations]).to eq([conversation, repeated])
  end

  it 'breaks equal adjusted scores by descending conversation ID' do
    newer = create(:conversation, account: account, inbox: inbox)
    hits << { '_score' => 10, 'fields' => { 'conversation_id' => [newer.id] } }
    expect(result[:conversations]).to eq([newer, conversation])
  end

  it 'rechecks live tenant and inbox permissions, including stale documents' do
    inaccessible = create(:conversation, account: account)
    foreign = create(:conversation)
    [inaccessible.id, foreign.id, 0].each { |id| hits.unshift('_score' => 100, 'fields' => { 'conversation_id' => [id] }) }
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
    hits.unshift({ '_score' => 100, 'fields' => { 'conversation_id' => [inaccessible.id] } },
                 { '_score' => 100, 'fields' => { 'conversation_id' => [0] } })
    expect(result[:conversations]).to eq([conversation])
  end

  it 'ranks the entire window before returning pages of 25 with no duplicated or missing conversations' do
    rows = create_list(:conversation, 25, account: account, inbox: inbox)
    hits.concat(rows.map { |row| { '_score' => 9, 'fields' => { 'conversation_id' => [row.id] } } })
    counts << { 'key' => rows.first.id, 'doc_count' => 10 }
    expect(result[:conversations]).to eq([rows.first, conversation] + rows.drop(2).reverse)
    expect(result.slice(:next_cursor, :has_more)).to eq(next_cursor: '25', has_more: true)
    expect(search.perform(cursor: '25')).to eq(conversations: [rows.second], next_cursor: nil, has_more: false)
    expect(search.perform(page: 2)[:conversations]).to eq([rows.second])
  end

  context 'when at the end of the result window' do
    before { stub_const("#{described_class}::RESULT_WINDOW", 2) }

    let(:cursor) { '1' }

    it 'ends pagination without requesting candidates beyond the initial relevance window' do
      inaccessible = create(:conversation, account: account)
      hits.unshift('_score' => 100, 'fields' => { 'conversation_id' => [inaccessible.id] })
      expect(result).to eq(conversations: [conversation], next_cursor: nil, has_more: false)
      expect(client).to have_received(:search).with(hash_including(body: hash_including(size: 2)))
      expect(search.perform(cursor: '2')[:conversations]).to be_empty
      expect(client).to have_received(:search).twice
    end
  end

  it 'skips the count query when no conversations match' do
    hits.clear
    expect(result[:conversations]).to be_empty
    expect(query).not_to have_received(:message_counts_body)
    expect(client).to have_received(:search).once
  end

  it 'rejects failed or timed-out shards instead of reporting incomplete results' do
    response['timed_out'] = true
    expect { result }.to raise_error(Searchkick::Error)
    response['timed_out'] = false
    response['_shards']['failed'] = 1
    expect { search.perform }.to raise_error(Searchkick::Error)
  end

  it 'rejects partial message counts instead of silently changing the ranking' do
    count_response['timed_out'] = true
    expect { result }.to raise_error(Searchkick::Error)
    count_response['timed_out'] = false
    count_response['_shards']['failed'] = 1
    expect { search.perform }.to raise_error(Searchkick::Error)
  end

  it 'rejects invalid cursors before querying' do
    expect { search.perform(cursor: '-1') }.to raise_error(ArgumentError)
    expect(client).not_to have_received(:search)
  end
end
