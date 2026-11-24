require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::BaseController', type: :request do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let!(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:agent) { create(:user, account: account, role: :agent) }

  before do
    create(:inbox_member, inbox: inbox, user: agent)
  end

  context 'when agent bot belongs to the account' do
    let(:agent_bot) { create(:agent_bot, account: account) }

    it 'allows assignments via API' do
      post api_v1_account_conversation_assignments_url(account_id: account.id, conversation_id: conversation.display_id),
           headers: { api_access_token: agent_bot.access_token.token },
           params: { assignee_id: agent.id },
           as: :json

      expect(response).to have_http_status(:success)
    end
  end

  context 'when agent bot belongs to another account' do
    let(:other_account) { create(:account) }
    let(:external_bot) { create(:agent_bot, account: other_account) }

    it 'rejects assignment' do
      post api_v1_account_conversation_assignments_url(account_id: account.id, conversation_id: conversation.display_id),
           headers: { api_access_token: external_bot.access_token.token },
           params: { assignee_id: agent.id },
           as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'when agent bot is global' do
    let(:global_bot) { create(:agent_bot, account: nil) }

    it 'rejects requests without inbox mapping' do
      post api_v1_account_conversation_assignments_url(account_id: account.id, conversation_id: conversation.display_id),
           headers: { api_access_token: global_bot.access_token.token },
           params: { assignee_id: agent.id },
           as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it 'allows requests when inbox mapping exists' do
      create(:agent_bot_inbox, agent_bot: global_bot, inbox: inbox)

      post api_v1_account_conversation_assignments_url(account_id: account.id, conversation_id: conversation.display_id),
           headers: { api_access_token: global_bot.access_token.token },
           params: { assignee_id: agent.id },
           as: :json

      expect(response).to have_http_status(:success)
    end
  end

  context 'when account enforces MFA' do
    before do
      skip('Skipping since MFA is not configured in this environment') unless Chatwoot.encryption_configured?
      account.update!(enforce_mfa: true)
    end

    it 'blocks api_access_token requests from non-enrolled users' do
      get "/api/v1/accounts/#{account.id}/conversations",
          headers: { api_access_token: agent.access_token.token },
          as: :json

      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body['error_code']).to eq('mfa_enrollment_required')
    end

    it 'allows enrolled users' do
      agent.enable_two_factor!
      agent.update!(otp_required_for_login: true)

      get "/api/v1/accounts/#{account.id}/conversations",
          headers: { api_access_token: agent.access_token.token },
          as: :json

      expect(response).to have_http_status(:success)
    end

    it 'allows saml users' do
      agent.update!(provider: 'saml')

      get "/api/v1/accounts/#{account.id}/conversations",
          headers: { api_access_token: agent.access_token.token },
          as: :json

      expect(response).to have_http_status(:success)
    end

    it 'allows agent bots' do
      agent_bot = create(:agent_bot, account: account)

      post api_v1_account_conversation_assignments_url(account_id: account.id, conversation_id: conversation.display_id),
           headers: { api_access_token: agent_bot.access_token.token },
           params: { assignee_id: agent.id },
           as: :json

      expect(response).to have_http_status(:success)
    end

    it 'does not gate devise-session requests' do
      get "/api/v1/accounts/#{account.id}/conversations",
          headers: agent.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:success)
    end
  end
end
