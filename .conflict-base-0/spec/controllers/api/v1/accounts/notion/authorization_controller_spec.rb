require 'rails_helper'

RSpec.describe 'Notion Authorization API', type: :request do
  let(:account) { create(:account) }

  describe 'POST /api/v1/accounts/{account.id}/notion/authorization' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/notion/authorization"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:administrator) { create(:user, account: account, role: :administrator) }

      it 'returns unauthorized for agent' do
        post "/api/v1/accounts/#{account.id}/notion/authorization",
             headers: agent.create_new_auth_token,
             params: { email: administrator.email },
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'creates a new authorization and returns the redirect url' do
        post "/api/v1/accounts/#{account.id}/notion/authorization",
             headers: administrator.create_new_auth_token,
             params: { email: administrator.email },
             as: :json

        expect(response).to have_http_status(:success)

        # Validate URL components
        url = response.parsed_body['url']
        uri = URI.parse(url)
        params = CGI.parse(uri.query)

        expect(url).to start_with('https://api.notion.com/v1/oauth/authorize')
        expect(params['response_type']).to eq(['code'])
        expect(params['owner']).to eq(['user'])
        expect(params['redirect_uri']).to eq(["#{ENV.fetch('FRONTEND_URL', 'http://localhost:3000')}/notion/callback"])

        # Validate state parameter exists and can be decoded back to the account
        expect(params['state']).to be_present
        decoded_account = GlobalID::Locator.locate_signed(params['state'].first, for: 'default')
        expect(decoded_account).to eq(account)
      end
    end
  end
end
