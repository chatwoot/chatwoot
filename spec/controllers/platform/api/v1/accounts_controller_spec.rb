require 'rails_helper'

RSpec.describe 'Platform Accounts API', type: :request do
  let!(:account) { create(:account) }

  describe 'POST /platform/api/v1/accounts' do
    context 'when it is an unauthenticated platform app' do
      it 'returns unauthorized' do
        post '/platform/api/v1/accounts'
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an invalid platform app token' do
      it 'returns unauthorized' do
        post '/platform/api/v1/accounts', params: { name: 'Test Account' },
                                          headers: { api_access_token: 'invalid' }, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated platform app' do
      let(:platform_app) { create(:platform_app) }

      it 'creates an account when and its permissible relationship' do
        post '/platform/api/v1/accounts', params: { name: 'Test Account' },
                                          headers: { api_access_token: platform_app.access_token.token }, as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Test Account')
        expect(platform_app.platform_app_permissibles.first.permissible.name).to eq('Test Account')
      end

      it 'creates an account with locale' do
        InstallationConfig.where(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS').first_or_create!(value: [{ 'name' => 'agent_management',
                                                                                                    'enabled' => true }])
        post '/platform/api/v1/accounts', params: { name: 'Test Account', locale: 'es' },
                                          headers: { api_access_token: platform_app.access_token.token }, as: :json

        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)
        expect(json_response['name']).to eq('Test Account')
        expect(json_response['locale']).to eq('es')
        expect(json_response['enabled_features']).to eq(
          {
            'agent_management' => true
          }
        )
      end

      it 'creates an account with feature flags' do
        InstallationConfig.where(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS').first_or_create!(value: [{ 'name' => 'inbox_management',
                                                                                                    'enabled' => true }])

        post '/platform/api/v1/accounts', params: { name: 'Test Account', enabled_features: %w[feature_ip_lookup feature_help_center] },
                                          headers: { api_access_token: platform_app.access_token.token }, as: :json

        json_response = JSON.parse(response.body)
        expect(json_response['name']).to include('Test Account')
        expect(json_response['enabled_features']).to eq(
          {
            'inbox_management' => true,
            'ip_lookup' => true,
            'help_center' => true
          }
        )
      end

      it 'creates an account with limits settings' do
        post '/platform/api/v1/accounts', params: { name: 'Test Account', limits: { agents: 5, inboxes: 10 } },
                                          headers: { api_access_token: platform_app.access_token.token }, as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Test Account')
        expect(response.body).to include('5')
        expect(response.body).to include('10')
      end
    end
  end

  describe 'GET /platform/api/v1/accounts/{account_id}' do
    context 'when it is an unauthenticated platform app' do
      it 'returns unauthorized' do
        get "/platform/api/v1/accounts/#{account.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an invalid platform app token' do
      it 'returns unauthorized' do
        get "/platform/api/v1/accounts/#{account.id}", headers: { api_access_token: 'invalid' }, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated platform app' do
      let(:platform_app) { create(:platform_app) }

      it 'returns unauthorized when its not a permissible object' do
        get "/platform/api/v1/accounts/#{account.id}", headers: { api_access_token: platform_app.access_token.token }, as: :json
        expect(response).to have_http_status(:unauthorized)
      end

      it 'shows an account when its permissible object' do
        create(:platform_app_permissible, platform_app: platform_app, permissible: account)

        get "/platform/api/v1/accounts/#{account.id}",
            headers: { api_access_token: platform_app.access_token.token }, as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include(account.name)
      end
    end
  end

  describe 'PATCH /platform/api/v1/accounts/{account_id}' do
    context 'when it is an unauthenticated platform app' do
      it 'returns unauthorized' do
        patch "/platform/api/v1/accounts/#{account.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an invalid platform app token' do
      it 'returns unauthorized' do
        patch "/platform/api/v1/accounts/#{account.id}", params: { name: 'Test Account' },
                                                         headers: { api_access_token: 'invalid' }, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated platform app' do
      let(:platform_app) { create(:platform_app) }

      it 'returns unauthorized when its not a permissible object' do
        patch "/platform/api/v1/accounts/#{account.id}", params: { name: 'Test Account' },
                                                         headers: { api_access_token: platform_app.access_token.token }, as: :json
        expect(response).to have_http_status(:unauthorized)
      end

      it 'updates an account when its permissible object' do
        create(:platform_app_permissible, platform_app: platform_app, permissible: account)

        patch "/platform/api/v1/accounts/#{account.id}", params: {
          name: 'Test Account',
          enabled_features: %w[feature_ip_lookup feature_help_center],
          limits: { agents: 5, inboxes: 10 }
        }, headers: { api_access_token: platform_app.access_token.token }, as: :json

        expect(response).to have_http_status(:success)
        expect(account.reload.name).to eq('Test Account')
        expect(account.reload.enabled_features['ip_lookup']).to be(true)
        expect(account.reload.enabled_features['help_center']).to be(true)
        expect(account.reload.limits['agents']).to eq(5)
        expect(account.reload.limits['inboxes']).to eq(10)
      end
    end
  end

  describe 'DELETE /platform/api/v1/accounts/{account_id}' do
    context 'when it is an unauthenticated platform app' do
      it 'returns unauthorized' do
        delete "/platform/api/v1/accounts/#{account.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an invalid platform app token' do
      it 'returns unauthorized' do
        delete "/platform/api/v1/accounts/#{account.id}", headers: { api_access_token: 'invalid' }, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated platform app' do
      let(:platform_app) { create(:platform_app) }

      it 'returns unauthorized when its not a permissible object' do
        delete "/platform/api/v1/accounts/#{account.id}", headers: { api_access_token: platform_app.access_token.token }, as: :json
        expect(response).to have_http_status(:unauthorized)
      end

      it 'destroys the object' do
        create(:platform_app_permissible, platform_app: platform_app, permissible: account)
        expect(DeleteObjectJob).to receive(:perform_later).with(account).once
        delete "/platform/api/v1/accounts/#{account.id}",
               headers: { api_access_token: platform_app.access_token.token }, as: :json

        expect(response).to have_http_status(:success)
      end
    end
  end
end
