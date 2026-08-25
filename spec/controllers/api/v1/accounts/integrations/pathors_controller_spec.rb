require 'rails_helper'

RSpec.describe 'Pathors Integration API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:bot_url) { 'https://backend.pathors.test/project/project-uuid-1/integration/chatwoot/callback' }
  let(:revoke_url) { 'https://api.pathors.test/oauth/revoke' }
  let(:refresh_token) { 'prt_refresh' }

  let(:hook) do
    create(:integrations_hook, account: account, app_id: 'pathors', access_token: 'pat_access',
                               settings: { organization_id: 'org-uuid-1', refresh_token: refresh_token })
  end
  let(:agent_bot) { create(:agent_bot, account: account, name: 'Pathors AI', outgoing_url: bot_url) }

  before do
    allow(GlobalConfigService).to receive(:load).and_call_original
    allow(GlobalConfigService).to receive(:load).with('PATHORS_API_URL', 'https://api.pathors.com').and_return('https://api.pathors.test')
    allow(GlobalConfigService).to receive(:load).with('PATHORS_OAUTH_CLIENT_ID', nil).and_return('test_client_id')
    allow(GlobalConfigService).to receive(:load).with('PATHORS_OAUTH_CLIENT_SECRET', nil).and_return('test_client_secret')
    stub_request(:post, revoke_url).to_return(status: 200, body: '', headers: {})
  end

  describe 'DELETE /api/v1/accounts/:account_id/integrations/pathors' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        hook
        agent_bot

        delete "/api/v1/accounts/#{account.id}/integrations/pathors", as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent' do
      it 'returns unauthorized and keeps the integration' do
        hook
        agent_bot

        delete "/api/v1/accounts/#{account.id}/integrations/pathors",
               headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(account.hooks.count).to eq(1)
        expect(account.agent_bots.count).to eq(1)
      end
    end

    context 'when it is an administrator' do
      it 'removes the hook and the agent bot', :aggregate_failures do
        hook
        agent_bot

        delete "/api/v1/accounts/#{account.id}/integrations/pathors",
               headers: admin.create_new_auth_token, as: :json

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq({})
        expect(account.hooks.count).to eq(0)
        expect(account.agent_bots.count).to eq(0)
      end

      it 'notifies Pathors exactly once through the signed agent bot webhook', :aggregate_failures do
        hook
        secret = agent_bot.secret

        delete "/api/v1/accounts/#{account.id}/integrations/pathors",
               headers: admin.create_new_auth_token, as: :json

        expect(AgentBots::WebhookJob).to have_been_enqueued.exactly(:once).with(
          bot_url,
          { event: 'integration.disconnected', account_id: account.id },
          :agent_bot_webhook,
          secret: secret
        )
      end

      it 'revokes the refresh token on the Pathors authorization server' do
        hook
        agent_bot

        delete "/api/v1/accounts/#{account.id}/integrations/pathors",
               headers: admin.create_new_auth_token, as: :json

        expect(WebMock).to have_requested(:post, revoke_url).with(
          body: {
            token: refresh_token,
            token_type_hint: 'refresh_token',
            client_id: 'test_client_id',
            client_secret: 'test_client_secret'
          }
        )
      end

      # The agent bot destroy clears the account's Pathors hooks on its own
      # (Pathors::BotDisconnectNotifiable), which here runs after this
      # controller's transaction already removed the hook. It has to find
      # nothing left and stay quiet rather than fail the request.
      it 'is unaffected by the hook cleanup that hangs off the bot destroy', :aggregate_failures do
        hook
        agent_bot

        delete "/api/v1/accounts/#{account.id}/integrations/pathors",
               headers: admin.create_new_auth_token, as: :json

        expect(response).to have_http_status(:ok)
        expect(Integrations::Hook.exists?(hook.id)).to be false
      end

      it 'falls back to the access token when the hook has no refresh token' do
        create(:integrations_hook, account: account, app_id: 'pathors', access_token: 'pat_access',
                                   settings: { organization_id: 'org-uuid-1' })
        agent_bot

        delete "/api/v1/accounts/#{account.id}/integrations/pathors",
               headers: admin.create_new_auth_token, as: :json

        expect(WebMock).to have_requested(:post, revoke_url).with(
          body: hash_including(token: 'pat_access', token_type_hint: 'access_token')
        )
      end

      it 'completes the local cleanup when Pathors cannot be reached', :aggregate_failures do
        stub_request(:post, revoke_url).to_timeout
        hook
        agent_bot

        delete "/api/v1/accounts/#{account.id}/integrations/pathors",
               headers: admin.create_new_auth_token, as: :json

        expect(response).to have_http_status(:ok)
        expect(account.hooks.count).to eq(0)
        expect(account.agent_bots.count).to eq(0)
      end

      it 'removes the hook when the agent bot is already gone', :aggregate_failures do
        hook

        delete "/api/v1/accounts/#{account.id}/integrations/pathors",
               headers: admin.create_new_auth_token, as: :json

        expect(response).to have_http_status(:ok)
        expect(account.hooks.count).to eq(0)
        expect(AgentBots::WebhookJob).not_to have_been_enqueued
      end

      it 'removes the agent bot when the hook is already gone', :aggregate_failures do
        agent_bot

        delete "/api/v1/accounts/#{account.id}/integrations/pathors",
               headers: admin.create_new_auth_token, as: :json

        expect(response).to have_http_status(:ok)
        expect(account.agent_bots.count).to eq(0)
        expect(WebMock).not_to have_requested(:post, revoke_url)
      end

      it 'returns not found when nothing is connected' do
        delete "/api/v1/accounts/#{account.id}/integrations/pathors",
               headers: admin.create_new_auth_token, as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
