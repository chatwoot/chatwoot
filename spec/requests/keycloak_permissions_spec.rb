require 'rails_helper'

RSpec.describe 'Keycloak role based API access', type: :request do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:limited_agent) { create(:user, account: account, role: :agent) }
  let(:manager) { create(:user, account: account, role: :agent) }
  let!(:conversation) { create(:conversation, account: account, inbox: inbox) }

  before do
    create(:inbox_member, user: limited_agent, inbox: inbox)
    Keycloak::RoleSyncService.new(user: limited_agent, keycloak_roles: ['keycloak:chatwoot_agent_limited']).perform
    Keycloak::RoleSyncService.new(user: manager, keycloak_roles: ['keycloak:chatwoot_manager']).perform
  end

  it 'returns 403 for automation rules to a limited agent' do
    get "/api/v1/accounts/#{account.id}/automation_rules", headers: limited_agent.create_new_auth_token

    expect(response).to have_http_status(:forbidden)
  end

  it 'lets a manager list automation rules' do
    get "/api/v1/accounts/#{account.id}/automation_rules", headers: manager.create_new_auth_token

    expect(response).to have_http_status(:success)
  end

  it 'blocks conversation deletion for a limited agent' do
    delete "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}", headers: limited_agent.create_new_auth_token

    expect(response).to have_http_status(:forbidden)
    expect(Conversation.exists?(conversation.id)).to be(true)
  end

  it 'allows conversation deletion for a manager' do
    delete "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}", headers: manager.create_new_auth_token

    expect(response).to have_http_status(:success)
  end

  it 'blocks contact export for a limited agent' do
    post "/api/v1/accounts/#{account.id}/contacts/export", headers: limited_agent.create_new_auth_token, params: {}

    expect(response).to have_http_status(:forbidden)
  end

  it 'exposes the synced permissions in the profile payload' do
    get '/api/v1/profile', headers: manager.create_new_auth_token

    permissions = response.parsed_body['accounts'].first['permissions']
    expect(permissions).to include('agent', 'can_delete_conversations')
  end
end

