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
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'creates a new authorization and returns the redirect url' do
        with_modified_env CRM_CALENDAR_MEETINGS_ENABLED: 'false' do
          post "/api/v1/accounts/#{account.id}/microsoft/authorization",
               headers: administrator.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:success)

          # Validate URL components
          url = response.parsed_body['url']
          uri = URI.parse(url)
          params = CGI.parse(uri.query)

          expect(url).to start_with('https://login.microsoftonline.com/common/oauth2/v2.0/authorize')
          expected_scope = [
            'offline_access https://outlook.office.com/IMAP.AccessAsUser.All ' \
            'https://graph.microsoft.com/Mail.Send https://graph.microsoft.com/Mail.ReadWrite openid profile email ' \
            'https://graph.microsoft.com/Calendars.ReadWrite'
          ]
          expect(params['scope']).to eq(expected_scope)
          expect(params['redirect_uri']).to eq(["#{ENV.fetch('FRONTEND_URL', 'http://localhost:3000')}/microsoft/callback"])
          expect(url).not_to match(/(?:\?|&)prompt=/)

          # Validate state parameter exists and can be decoded back to the account
          expect(params['state']).to be_present
          decoded_account = GlobalID::Locator.locate_signed(params['state'].first, for: 'default')
          expect(decoded_account).to eq(account)
        end
      end

      it 'builds the authorize url on the tenant-specific endpoint when the account app has a tenant_id' do
        account.email_oauth_apps.create!(
          provider: 'microsoft', client_id: SecureRandom.uuid, client_secret: SecureRandom.hex(20),
          tenant_id: 'a1b2c3d4-1111-2222-3333-444455556666'
        )

        post "/api/v1/accounts/#{account.id}/microsoft/authorization",
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['url'])
          .to start_with('https://login.microsoftonline.com/a1b2c3d4-1111-2222-3333-444455556666/oauth2/v2.0/authorize')
      end
    end
  end
end
