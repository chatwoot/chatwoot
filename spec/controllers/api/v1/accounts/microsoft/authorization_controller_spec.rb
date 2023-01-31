require 'rails_helper'

RSpec.describe 'Microsoft Authorization API', type: :request do
  let(:account) { create(:account) }

  describe 'POST /api/v1/accounts/{account.id}/microsoft/authorization' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/microsoft/authorization"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:administrator) { create(:user, account: account, role: :administrator) }

      it 'returns unathorized for agent' do
        post "/api/v1/accounts/#{account.id}/microsoft/authorization",
             headers: agent.create_new_auth_token,
             params: { email: administrator.email },
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'creates a new authorization and returns the redirect url' do
        post "/api/v1/accounts/#{account.id}/microsoft/authorization",
             headers: administrator.create_new_auth_token,
             params: { email: administrator.email },
             as: :json

        expect(response).to have_http_status(:success)
        microsoft_service = Class.new { extend MicrosoftConcern }
        response_url = microsoft_service.microsoft_client.auth_code.authorize_url(
          {
            redirect_uri: "#{ENV.fetch('FRONTEND_URL', 'http://localhost:3000')}/microsoft/callback",
            scope: 'offline_access https://outlook.office.com/IMAP.AccessAsUser.All https://outlook.office.com/SMTP.Send openid',
            prompt: 'consent'
          }
        )
        expect(JSON.parse(response.body)['url']).to eq response_url
        expect(::Redis::Alfred.get(administrator.email)).to eq(account.id.to_s)
      end
    end
  end
end
