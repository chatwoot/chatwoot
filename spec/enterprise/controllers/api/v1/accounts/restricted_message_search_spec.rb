require 'rails_helper'

RSpec.describe 'Restricted indexed message search', if: Message.respond_to?(:search), type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account) }
  let(:role) { create(:custom_role, account: account, permissions: ['conversation_participating_manage']) }
  let(:inbox) { create(:inbox, account: account, enable_auto_assignment: false) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: agent) }
  let(:message) { create(:message, account: account, conversation: conversation) }
  let(:path) { "/api/v1/accounts/#{account.id}/search/messages" }
  let(:headers) { agent.create_new_auth_token }
  let(:timestamp) { Time.current.to_i * 1000 }

  before do
    account.enable_features!('advanced_search')
    account.disable_features!('search_with_gin')
    create(:inbox_member, inbox: inbox, user: agent)
    account.account_users.find_by!(user: agent).update!(custom_role: role)
  end

  it 'stops after 10,000 candidates and can find the next permitted hit on continuation' do
    create(:inbox, account: account)
    eligible_hit = hit(message.id)
    # IDs absent from the current SQL scope stand in for inaccessible indexed hits.
    batches = (1..10_000).map { |n| hit(message.id + n) }.reverse.each_slice(1000).to_a
    after = nil
    (batches + [[eligible_hit]]).each do |hits|
      body_options = { track_total_hits: false }
      body_options[:search_after] = after if after
      options = hash_including(body_options: body_options, limit: 1000, where: hash_including(account_id: account.id, inbox_id: [inbox.id]))
      expect(Message).to receive(:search).with('invoice', options).ordered.and_return(index_results(hits))
      after = hits.last.fetch('sort')
    end

    get path, headers: headers, params: { q: 'invoice', per_page: 5 }
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig('payload', 'messages')).to eq([])
    cursor = response.parsed_body.dig('meta', 'message_pagination', 'next_cursor')
    expect(cursor).to be_present

    get path, headers: headers, params: { q: 'invoice', page: 2, per_page: 5, cursor: cursor }
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig('payload', 'messages').pluck('id')).to eq([message.id])
    expect(response.parsed_body.dig('meta', 'message_pagination')).to eq('next_cursor' => nil)
  end

  it 'resumes at the first unused hit when a page fills and checks current access again' do
    messages = create_list(:message, 7, account: account, conversation: conversation).reverse
    hits = messages.map { |record| hit(record.id) }
    expect(Message).to receive(:search).with('invoice', hash_including(body_options: { track_total_hits: false }))
                                       .and_return(index_results(hits))

    get path, headers: headers, params: { q: 'invoice', per_page: 5 }
    expect(response.parsed_body.dig('payload', 'messages').pluck('id')).to eq(messages.first(5).map(&:id))
    cursor = response.parsed_body.dig('meta', 'message_pagination', 'next_cursor')
    expect(cursor).to be_present

    last_hit = create(:message, account: account, conversation: create(:conversation, account: account, inbox: inbox, assignee: agent))
    conversation.update!(assignee: nil)
    tail = [hits.fetch(5), hits.fetch(6), hit(last_hit.id, timestamp - 1)]
    expect(Message).to receive(:search)
      .with('invoice', hash_including(body_options: { track_total_hits: false, search_after: hits.fetch(4).fetch('sort') }))
      .and_return(index_results(tail))

    get path, headers: headers, params: { q: 'invoice', page: 2, per_page: 5, cursor: cursor }
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig('payload', 'messages').pluck('id')).to eq([last_hit.id])
  end

  it 'uses the requesting agent permissions with a cursor from the same account' do
    other_agent = create(:user, account: account)
    create(:inbox_member, inbox: inbox, user: other_agent)
    account.account_users.find_by!(user: other_agent).update!(custom_role: role)
    other_conversation = create(:conversation, account: account, inbox: inbox, assignee: other_agent)
    visible = create(:message, account: account, conversation: other_conversation)
    cursor = Search::MessageSearchCursor.new(account.id).write(after: [timestamp + 1, visible.id + 1], offset: 0)
    allow(Message).to receive(:search).and_return(index_results([hit(visible.id), hit(message.id, timestamp - 1)]))

    get path, headers: other_agent.create_new_auth_token, params: { q: 'invoice', page: 2, per_page: 5, cursor: cursor }
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig('payload', 'messages').pluck('id')).to eq([visible.id])
  end

  it 'rejects a cursor from a different account before searching the index' do
    other_account = create(:account)
    cursor = Search::MessageSearchCursor.new(other_account.id).write(after: [timestamp, 1], offset: 0)
    allow(Message).to receive(:search)

    get path, headers: headers, params: { q: 'invoice', per_page: 5, cursor: cursor }
    expect(response).to have_http_status(:unprocessable_entity)
    expect(Message).not_to have_received(:search)
  end

  it 'reports an index timeout as retryable for a restricted search' do
    allow(Message).to receive(:search).and_return(index_results([], response: { 'timed_out' => true }))
    allow(ChatwootExceptionTracker).to receive(:new).and_return(instance_double(ChatwootExceptionTracker, capture_exception: nil))

    get path, headers: headers, params: { q: 'invoice', per_page: 5 }
    expect(response).to have_http_status(:service_unavailable)
  end

  it 'fails visibly when a legacy index cannot provide a stable continuation' do
    records = create_list(:message, 6, account: account, conversation: conversation).reverse
    hits = records.map { |record| hit(record.id).merge('sort' => [timestamp, nil]) }
    allow(Message).to receive(:search).and_return(index_results(hits))
    allow(ChatwootExceptionTracker).to receive(:new).and_return(instance_double(ChatwootExceptionTracker, capture_exception: nil))

    get path, headers: headers, params: { q: 'invoice', per_page: 5 }
    expect(response).to have_http_status(:service_unavailable)
  end

  def hit(id, created_at = timestamp)
    { '_id' => id.to_s, 'sort' => [created_at, id] }
  end

  def index_results(hits, response: {})
    instance_double(Searchkick::Results, hits: hits, response: response)
  end
end
