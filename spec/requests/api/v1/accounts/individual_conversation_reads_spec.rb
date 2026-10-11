require 'rails_helper'

RSpec.describe 'Individual conversation reads', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:seller) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: seller, read_baseline_at: 1.day.ago) }
  let(:path) { "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}" }
  let(:admin_headers) { admin.create_new_auth_token }
  let(:seller_headers) { seller.create_new_auth_token }

  before do
    account.enable_features!(:individual_conversation_reads, :conversation_unread_counts)
    account.disable_features!(:unread_count_for_filters)
    create(:inbox_member, inbox: inbox, user: seller)
    create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming, created_at: 1.minute.ago)
  end

  it 'keeps the seller unread after an administrator reads, across detail, list and sidebar counts' do
    post "#{path}/update_last_seen", headers: admin_headers, as: :json
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body['unread_count']).to eq(0)

    get path, headers: seller_headers, as: :json
    expect(response.parsed_body['unread_count']).to eq(1)
    get "#{path}/messages", headers: seller_headers, as: :json
    expect(Time.iso8601(response.parsed_body.dig('meta', 'agent_last_seen_at'))).to be_within(1.second).of(conversation.read_baseline_at)
    get "/api/v1/accounts/#{account.id}/conversations", headers: seller_headers, as: :json
    expect(response.parsed_body.dig('data', 'payload').find { |c| c['id'] == conversation.display_id }['unread_count']).to eq(1)

    get "/api/v1/accounts/#{account.id}/conversations/unread_counts", headers: seller_headers, as: :json
    expect(response.parsed_body.dig('payload', 'all_count')).to eq(1)
    get "/api/v1/accounts/#{account.id}/conversations/unread_counts", headers: admin_headers, as: :json
    expect(response.parsed_body.dig('payload', 'all_count')).to eq(0)
  end

  it 'marks unread only for the acting user and retains the other users read receipt' do
    post "#{path}/update_last_seen", headers: admin_headers, as: :json
    post "#{path}/update_last_seen", headers: seller_headers, as: :json
    post "#{path}/unread", headers: admin_headers, as: :json
    expect(response.parsed_body['unread_count']).to eq(1)
    get path, headers: seller_headers, as: :json
    expect(response.parsed_body['unread_count']).to eq(0)
    expect(conversation.conversation_read_states.count).to eq(2)
  end

  it 'shares one receipt across two sessions of the same person' do
    second_headers = admin.create_new_auth_token
    post "#{path}/update_last_seen", headers: admin_headers, as: :json
    get path, headers: second_headers, as: :json
    expect(response.parsed_body['unread_count']).to eq(0)
    expect(conversation.conversation_read_states.where(user: admin).count).to eq(1)
  end

  it 'keeps the activation baseline stable when another person reads new messages' do
    conversation.update!(read_baseline_at: 2.minutes.ago, agent_last_seen_at: Time.current)
    post "#{path}/update_last_seen", headers: admin_headers, as: :json
    expect(conversation.reload.read_baseline_at).to be_within(2.seconds).of(2.minutes.ago)
    get path, headers: seller_headers, as: :json
    expect(response.parsed_body['unread_count']).to eq(1)
  end

  it 'rejects readers outside the account without creating a receipt' do
    outsider = create(:user)
    post "#{path}/update_last_seen", headers: outsider.create_new_auth_token, as: :json
    expect(response).to have_http_status(:unauthorized)
    expect(conversation.conversation_read_states).to be_empty
  end
end
