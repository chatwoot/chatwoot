require 'rails_helper'

RSpec.describe 'Instagram Unified Login connections', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:token) do
    Instagram::PendingConnection.create(account_id: account.id, accounts: [{ 'id' => 'ig1', 'username' => 'test' }],
                                        token_response: { 'access_token' => 'secret_token' }, configuration_id: 'config1')
  end
  let(:path) { "/api/v1/accounts/#{account.id}/instagram" }

  around do |example|
    with_modified_env(ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY: 'primary', ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY: 'deterministic',
                      ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT: 'salt') { example.run }
  end

  it 'returns account choices without exposing the access token' do
    post "#{path}/accounts", headers: admin.create_new_auth_token, params: { connection_token: token }, as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq('accounts' => [{ 'id' => 'ig1', 'username' => 'test' }])
    expect(response.body).not_to include('secret_token')
  end

  it 'requires administrator access' do
    agent = create(:user, account: account, role: :agent)
    post "#{path}/accounts", headers: agent.create_new_auth_token, params: { connection_token: token }, as: :json
    expect(response).to have_http_status(:unauthorized)
  end

  it 'rejects another account connection token' do
    other_account = create(:account)
    other_admin = create(:user, account: other_account, role: :administrator)
    post "/api/v1/accounts/#{other_account.id}/instagram/accounts", headers: other_admin.create_new_auth_token,
                                                                    params: { connection_token: token }, as: :json
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'rejects an unshared account without creating an inbox' do
    expect do
      post "#{path}/connections", headers: admin.create_new_auth_token,
                                  params: { connection_token: token, instagram_id: 'unshared' }, as: :json
    end.not_to change(Inbox, :count)
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'creates the selected inbox and consumes the pending connection' do
    stub_request(:post, 'https://graph.facebook.com/v22.0/ig1/subscribed_apps')
      .with(query: { subscribed_fields: 'messages,message_reactions,messaging_seen' }).to_return(body: { success: true }.to_json)
    post "#{path}/connections", headers: admin.create_new_auth_token,
                                params: { connection_token: token, instagram_id: 'ig1' }, as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body['redirect_url']).to include("/settings/inboxes/new/#{Inbox.last.id}/agents")
    post "#{path}/accounts", headers: admin.create_new_auth_token, params: { connection_token: token }, as: :json
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'rejects an expired connection' do
    saved_token = token
    key = Instagram::PendingConnection.cache_key(account.id, saved_token)
    expect(Redis::Alfred.ttl(key)).to be_between(1, 600)
    Redis::SecureStorage.delete(key)
    post "#{path}/accounts", headers: admin.create_new_auth_token, params: { connection_token: saved_token }, as: :json
    expect(response).to have_http_status(:unprocessable_entity)
  end

  context 'when reconnecting an inbox' do
    let(:channel) { create(:channel_instagram, account: account, instagram_id: 'ig1', auth_type: 'unified_login') }
    let(:token) do
      Instagram::PendingConnection.create(
        account_id: account.id, inbox_id: channel.inbox.id,
        accounts: [{ 'id' => 'ig1', 'username' => 'test' }],
        token_response: { 'access_token' => 'secret_token' }, configuration_id: 'config1'
      )
    end

    it 'only offers the original account when reconnecting' do
      post "#{path}/accounts", headers: admin.create_new_auth_token, params: { connection_token: token }, as: :json
      expect(response.parsed_body['accounts']).to eq([{ 'id' => 'ig1', 'username' => 'test' }])
    end

    it 'rejects a different account, then reconnects the original inbox without creating another' do
      saved_token = token
      channel.inbox.update!(name: 'Original inbox')
      original_token = channel[:access_token]
      expect do
        post "#{path}/connections", headers: admin.create_new_auth_token,
                                    params: { connection_token: saved_token, instagram_id: 'ig2' }, as: :json
      end.not_to change(Inbox, :count)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(channel.reload[:access_token]).to eq(original_token)

      stub_request(:post, 'https://graph.facebook.com/v22.0/ig1/subscribed_apps')
        .with(query: { subscribed_fields: 'messages,message_reactions,messaging_seen' }).to_return(body: { success: true }.to_json)
      expect do
        post "#{path}/connections", headers: admin.create_new_auth_token,
                                    params: { connection_token: saved_token, instagram_id: 'ig1' }, as: :json
      end.not_to change(Inbox, :count)
      expect(response.parsed_body['redirect_url']).to end_with("/settings/inboxes/#{channel.inbox.id}")
      expect(channel.reload).to have_attributes(auth_type: 'unified_login', access_token: 'secret_token')
      expect(channel.inbox.name).to eq('Original inbox')
    end

    it 'does not recreate a missing target inbox' do
      missing_token = Instagram::PendingConnection.create(
        account_id: account.id, inbox_id: 0, accounts: [{ 'id' => 'ig1', 'username' => 'test' }],
        token_response: { 'access_token' => 'secret_token' }, configuration_id: 'config1'
      )
      expect do
        post "#{path}/connections", headers: admin.create_new_auth_token,
                                    params: { connection_token: missing_token, instagram_id: 'ig1' }, as: :json
      end.not_to change(Inbox, :count)
      expect(response).to have_http_status(:not_found)
    end
  end
end
