require 'rails_helper'

RSpec.describe 'Platform Account Users API', type: :request do
  let!(:account) { create(:account) }

  describe 'GET /platform/api/v1/accounts/{account_id}/account_users' do
    context 'when it is an unauthenticated platform app' do
      it 'returns unauthorized' do
        get "/platform/api/v1/accounts/#{account.id}/account_users"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated platform app' do
      let(:platform_app) { create(:platform_app) }
      let!(:account_user) { create(:account_user, account: account) }

      it 'returns all the account users for the account' do
        create(:platform_app_permissible, platform_app: platform_app, permissible: account)

        get "/platform/api/v1/accounts/#{account.id}/account_users",
            headers: { api_access_token: platform_app.access_token.token }, as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include(account_user.id.to_s)
      end
    end
  end

  describe 'POST /platform/api/v1/accounts/{account_id}/account_users' do
    context 'when it is an unauthenticated platform app' do
      it 'returns unauthorized' do
        post "/platform/api/v1/accounts/#{account.id}/account_users"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated platform app' do
      let(:platform_app) { create(:platform_app) }

      it 'creates a new account user for the account' do
        user = create(:user)
        create(:platform_app_permissible, platform_app: platform_app, permissible: account)

        post "/platform/api/v1/accounts/#{account.id}/account_users",
             params: { user_id: user.id, role: 'administrator' },
             headers: { api_access_token: platform_app.access_token.token }, as: :json

        expect(response).to have_http_status(:success)
        data = response.parsed_body
        expect(data['user_id']).to eq(user.id)
      end

      it 'updates the new account user for the account' do
        create(:platform_app_permissible, platform_app: platform_app, permissible: account)
        account_user = create(:account_user, account: account, role: 'agent')

        post "/platform/api/v1/accounts/#{account.id}/account_users",
             params: { user_id: account_user.user_id, role: 'administrator' },
             headers: { api_access_token: platform_app.access_token.token }, as: :json

        expect(response).to have_http_status(:success)
        data = response.parsed_body
        expect(data['role']).to eq('administrator')
      end
    end
  end

  describe 'DELETE /platform/api/v1/accounts/{account_id}/account_users' do
    let(:account_user) { create(:account_user, account: account, role: 'agent') }

    context 'when it is an unauthenticated platform app' do
      it 'returns unauthorized' do
        delete "/platform/api/v1/accounts/#{account.id}/account_users", params: { user_id: account_user.user_id }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated platform app' do
      let(:platform_app) { create(:platform_app) }

      it 'returns deletes the account user' do
        create(:platform_app_permissible, platform_app: platform_app, permissible: account)

        delete "/platform/api/v1/accounts/#{account.id}/account_users", params: { user_id: account_user.user_id },
                                                                        headers: { api_access_token: platform_app.access_token.token }, as: :json

        expect(response).to have_http_status(:success)
        expect(account.account_users.count).to eq 0
      end
    end
  end
end
