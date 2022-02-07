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

        patch "/platform/api/v1/accounts/#{account.id}", params: { name: 'Test Account' },
                                                         headers: { api_access_token: platform_app.access_token.token }, as: :json

        expect(response).to have_http_status(:success)
        expect(account.reload.name).to eq('Test Account')
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
