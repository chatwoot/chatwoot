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
                                          headers: { 'api-access-token': 'invalid' }, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated platform app' do
      let(:platform_app) { create(:platform_app) }

      it 'creates an account when and its permissible relationship' do
        post '/platform/api/v1/accounts', params: { name: 'Test Account' },
                                          headers: { 'api-access-token': platform_app.access_token.token }, as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Test Account')
        expect(platform_app.platform_app_permissibles.first.permissible.name).to eq('Test Account')
      end

      it 'creates an account with locale' do
        InstallationConfig.where(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS').first_or_create!(value: [{ 'name' => 'agent_management',
                                                                                                    'enabled' => true }])
        post '/platform/api/v1/accounts', params: { name: 'Test Account', locale: 'es' },
                                          headers: { 'api-access-token': platform_app.access_token.token }, as: :json

        expect(response).to have_http_status(:success)

        json_response = response.parsed_body
        expect(json_response['name']).to eq('Test Account')
        expect(json_response['locale']).to eq('es')
        expect(json_response['features']['agent_management']).to be(true)
      end

      it 'creates an account with feature flags' do
        InstallationConfig.where(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS').first_or_create!(value: [{ 'name' => 'inbox_management',
                                                                                                    'enabled' => true },
                                                                                                  { 'name' => 'disable_branding',
                                                                                                    'enabled' => true },
                                                                                                  { 'name' => 'help_center',
                                                                                                    'enabled' => false }])

        post '/platform/api/v1/accounts', params: { name: 'Test Account', features: {
          ip_lookup: true,
          help_center: true,
          disable_branding: false
        } }, headers: { 'api-access-token': platform_app.access_token.token }, as: :json

        json_response = response.parsed_body
        created_account = Account.find(json_response['id'])
        # The platform API must apply the features passed in the request:
        # ip_lookup/help_center were requested on, disable_branding was
        # requested off (it defaults on via ACCOUNT_LEVEL_FEATURE_DEFAULTS),
        # and inbox_management stays on from the account defaults.
        expect(created_account.feature_enabled?('inbox_management')).to be(true)
        expect(created_account.feature_enabled?('ip_lookup')).to be(true)
        expect(created_account.feature_enabled?('help_center')).to be(true)
        expect(created_account.feature_enabled?('disable_branding')).to be(false)
        expect(json_response['name']).to include('Test Account')
        expect(json_response['features'].keys).to include('inbox_management', 'ip_lookup', 'help_center')
      end

      it 'creates an account with limits settings' do
        post '/platform/api/v1/accounts', params: { name: 'Test Account', limits: { agents: 5, inboxes: 10 } },
                                          headers: { 'api-access-token': platform_app.access_token.token }, as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Test Account')
        expect(response.body).to include('5')
        expect(response.body).to include('10')
      end
    end
  end

  describe 'GET /platform/api/v1/accounts' do
    context 'when it is an unauthenticated platform app' do
      it 'returns unauthorized' do
        get '/platform/api/v1/accounts'
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an invalid platform app token' do
      it 'returns unauthorized' do
        get '/platform/api/v1/accounts', headers: { 'api-access-token': 'invalid' }, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated platform app' do
      let(:platform_app) { create(:platform_app) }
      let!(:account1) { create(:account, name: 'Account A') }
      let!(:account2) { create(:account, name: 'Account B') }

      before do
        create(:platform_app_permissible, platform_app: platform_app, permissible: account1)
        create(:platform_app_permissible, platform_app: platform_app, permissible: account2)
      end

      it 'returns all permissible accounts' do
        get '/platform/api/v1/accounts', headers: { 'api-access-token': platform_app.access_token.token }, as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response.size).to eq(2)
        expect(json_response.map { |acc| acc['name'] }).to include('Account A', 'Account B')
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
        get "/platform/api/v1/accounts/#{account.id}", headers: { 'api-access-token': 'invalid' }, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated platform app' do
      let(:platform_app) { create(:platform_app) }

      it 'returns unauthorized when its not a permissible object' do
        get "/platform/api/v1/accounts/#{account.id}", headers: { 'api-access-token': platform_app.access_token.token }, as: :json
        expect(response).to have_http_status(:unauthorized)
      end

      it 'shows an account when its permissible object' do
        create(:platform_app_permissible, platform_app: platform_app, permissible: account)

        get "/platform/api/v1/accounts/#{account.id}",
            headers: { 'api-access-token': platform_app.access_token.token }, as: :json

        expect(response).to have_http_status(:success)
        expect(response).to conform_schema(200)
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
                                                         headers: { 'api-access-token': 'invalid' }, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated platform app' do
      let(:platform_app) { create(:platform_app) }

      it 'returns unauthorized when its not a permissible object' do
        patch "/platform/api/v1/accounts/#{account.id}", params: { name: 'Test Account' },
                                                         headers: { 'api-access-token': platform_app.access_token.token }, as: :json
        expect(response).to have_http_status(:unauthorized)
      end

      it 'updates an account when its permissible object' do
        create(:platform_app_permissible, platform_app: platform_app, permissible: account)
        account.enable_features!('inbox_management', 'channel_facebook')

        patch "/platform/api/v1/accounts/#{account.id}", params: {
          name: 'Test Account',
          features: {
            ip_lookup: true,
            help_center: true,
            channel_facebook: false
          },
          limits: { agents: 5, inboxes: 10 }
        }, headers: { 'api-access-token': platform_app.access_token.token }, as: :json

        expect(response).to have_http_status(:success)
        account.reload
        expect(account.name).to eq('Test Account')
        # The update must apply the features passed in the request:
        # ip_lookup/help_center requested on, channel_facebook requested off
        # (it was enabled before the update), inbox_management stays on.
        expect(account.enabled_features).to include('inbox_management', 'ip_lookup', 'help_center')
        expect(account.feature_enabled?('channel_facebook')).to be(false)
        expect(account.limits['agents']).to eq(5)
        expect(account.limits['inboxes']).to eq(10)
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
        delete "/platform/api/v1/accounts/#{account.id}", headers: { 'api-access-token': 'invalid' }, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated platform app' do
      let(:platform_app) { create(:platform_app) }

      it 'returns unauthorized when its not a permissible object' do
        delete "/platform/api/v1/accounts/#{account.id}", headers: { 'api-access-token': platform_app.access_token.token }, as: :json
        expect(response).to have_http_status(:unauthorized)
      end

      it 'destroys the object' do
        create(:platform_app_permissible, platform_app: platform_app, permissible: account)
        expect(DeleteObjectJob).to receive(:perform_later).with(account).once
        delete "/platform/api/v1/accounts/#{account.id}",
               headers: { 'api-access-token': platform_app.access_token.token }, as: :json

        expect(response).to have_http_status(:success)
      end
    end
  end
end
