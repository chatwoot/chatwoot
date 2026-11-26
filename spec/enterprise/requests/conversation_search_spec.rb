require 'rails_helper'

RSpec.describe 'Ranked conversation search', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, last_activity_at: 10.days.ago) }
  let(:client) { instance_double(OpenSearch::Client) }
  let(:headers) { agent.create_new_auth_token }
  let(:params) { { q: 'message-only-needle' } }

  before do
    conversation
    create(:inbox_member, user: agent, inbox: inbox)
    account.enable_features!('advanced_search', 'advanced_search_conversations')
    allow(ChatwootApp).to receive(:advanced_search_allowed?).and_return(true)
    query = instance_double(SearchIndexing::ConversationSearchQuery, body: {}, message_counts_body: { size: 0 })
    allow(SearchIndexing::ConversationSearchQuery).to receive(:new).and_return(query)
    allow(Searchkick).to receive(:client).and_return(client)
    allow(client).to receive(:search).and_return('_shards' => { 'failed' => 0 },
                                                 'hits' => { 'hits' => [{ '_score' => 10, 'fields' => { 'conversation_id' => [conversation.id] } }] })
    allow(client).to receive(:search).with(index: 'messages_test', body: { size: 0 })
                                     .and_return('_shards' => { 'failed' => 0 }, 'aggregations' => { 'conversations' => { 'buckets' => [] } })
    without_partial_double_verification do
      allow(Message).to receive(:search_index).and_return(Searchkick::Index.new('messages_test'))
    end
  end

  it 'renders engine-only matches in the existing conversation shape with pagination metadata' do
    get "/api/v1/accounts/#{account.id}/search/conversations", params: params, headers: headers
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig('payload', 'conversations').pluck('id')).to eq([conversation.display_id])
    expect(response.parsed_body['meta']).to eq('next_cursor' => nil, 'has_more' => false)
  end

  it 'applies conversation activity dates to matches from either index' do
    get "/api/v1/accounts/#{account.id}/search/conversations", params: params.merge(since: 5.days.ago.to_i), headers: headers
    expect(response.parsed_body.dig('payload', 'conversations')).to be_empty
  end

  it 'validates continuation offsets' do
    get "/api/v1/accounts/#{account.id}/search/conversations", params: params.merge(conversation_cursor: 'invalid'), headers: headers
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'reports an unavailable engine distinctly from an empty result' do
    allow(client).to receive(:search).and_raise(Faraday::ConnectionFailed)
    get "/api/v1/accounts/#{account.id}/search/conversations", params: params, headers: headers
    expect(response.parsed_body['meta']).to eq('error' => true)
  end

  it 'reports failed message counting as a retryable search error' do
    allow(client).to receive(:search).with(index: 'messages_test', body: { size: 0 }).and_raise(Faraday::ConnectionFailed)
    get "/api/v1/accounts/#{account.id}/search/conversations", params: params, headers: headers
    expect(response.parsed_body['meta']).to eq('error' => true)
    expect(response.parsed_body.dig('payload', 'conversations')).to be_empty
  end
end
