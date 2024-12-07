require 'rails_helper'

RSpec.describe 'Captain Integrations API', type: :request do
  let!(:account) { create(:account) }
  let!(:agent) { create(:user, account: account, role: :agent) }
  let!(:hook) do
    create(:integrations_hook, account: account, app_id: 'captain', settings: {
             access_token: SecureRandom.hex,
             account_email: Faker::Internet.email,
             assistant_id: '1',
             account_id: '1'
           })
  end
  let(:captain_api_url) { 'https://captain.example.com/' }

  before do
    InstallationConfig.where(name: 'CAPTAIN_API_URL').first_or_create(value: captain_api_url)
  end

  describe 'POST /api/v1/accounts/{account.id}/integrations/captain/proxy' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post proxy_api_v1_account_integrations_captain_url(account_id: account.id),
             params: { method: 'get', route: 'some_route' },
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      context 'when valid request method and route' do
        let(:route) { 'some_route' }
        let(:method) { 'get' }

        it 'proxies the request to Captain API' do
          stub_request(:get, "#{captain_api_url}api/accounts/#{hook.settings['account_id']}/#{route}")
            .with(headers: {
                    'X-User-Email' => hook.settings['account_email'],
                    'X-User-Token' => hook.settings['access_token'],
                    'Content-Type' => 'application/json'
                  })
            .to_return(status: 200, body: 'Success', headers: {})

          post proxy_api_v1_account_integrations_captain_url(account_id: account.id),
               params: { method: method, route: route },
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:success)
          expect(response.body).to eq('Success')
        end
      end

      context 'when HTTP method is invalid' do
        it 'returns unprocessable entity' do
          post proxy_api_v1_account_integrations_captain_url(account_id: account.id),
               params: { method: 'invalid', route: 'some_route', body: { some: 'data' } },
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:internal_server_error)
        end
      end

      context 'when the hook is not found' do
        before { hook.destroy }

        it 'returns not found' do
          post proxy_api_v1_account_integrations_captain_url(account_id: account.id),
               params: { method: 'get', route: 'some_route' },
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end
end
