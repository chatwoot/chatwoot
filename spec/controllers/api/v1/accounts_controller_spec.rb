require 'rails_helper'

RSpec.describe 'Accounts API', type: :request do
  describe 'POST /api/v1/accounts' do
    let(:email) { Faker::Internet.email }

    context 'when posting to accounts with correct parameters' do
      let(:account_builder) { double }
      let(:account) { create(:account) }
      let(:user) { create(:user, email: email, account: account) }

      before do
        allow(AccountBuilder).to receive(:new).and_return(account_builder)
        ENV['ENABLE_ACCOUNT_SIGNUP'] = nil
      end

      it 'calls account builder' do
        allow(account_builder).to receive(:perform).and_return([user, account])

        params = { account_name: 'test', email: email, user: nil }

        post api_v1_accounts_url,
             params: params,
             as: :json

        expect(AccountBuilder).to have_received(:new).with(params.merge(confirmed: false))
        expect(account_builder).to have_received(:perform)
        expect(response.headers.keys).to include('access-token', 'token-type', 'client', 'expiry', 'uid')
      end

      it 'renders error response on invalid params' do
        allow(account_builder).to receive(:perform).and_return(nil)

        params = { account_name: nil, email: nil, user: nil }

        post api_v1_accounts_url,
             params: params,
             as: :json

        expect(AccountBuilder).to have_received(:new).with(params.merge(confirmed: false))
        expect(account_builder).to have_received(:perform)
        expect(response).to have_http_status(:forbidden)
        expect(response.body).to eq({ message: I18n.t('errors.signup.failed') }.to_json)
      end

      it 'ignores confirmed param when called with out super admin token' do
        allow(account_builder).to receive(:perform).and_return(nil)

        params = { account_name: 'test', email: email, confirmed: true, user: nil }

        post api_v1_accounts_url,
             params: params,
             as: :json

        expect(AccountBuilder).to have_received(:new).with(params.merge(confirmed: false))
        expect(account_builder).to have_received(:perform)
        expect(response).to have_http_status(:forbidden)
        expect(response.body).to eq({ message: I18n.t('errors.signup.failed') }.to_json)
      end
    end

    context 'when called with super admin token' do
      let(:super_admin) { create(:super_admin) }

      it 'calls account builder with confirmed true when confirmed param is passed' do
        params = { account_name: 'test', email: email, confirmed: true }

        post api_v1_accounts_url,
             params: params,
             headers: { api_access_token: super_admin.access_token.token },
             as: :json

        created_user = User.find_by(email: email)
        expect(created_user.confirmed?).to eq(true)
        expect(response.headers.keys).to include('access-token', 'token-type', 'client', 'expiry', 'uid')
        expect(response.body).to include(created_user.access_token.token)
      end
    end

    context 'when ENABLE_ACCOUNT_SIGNUP env variable is set to false' do
      it 'responds 404 on requests' do
        params = { account_name: 'test', email: email }
        ENV['ENABLE_ACCOUNT_SIGNUP'] = 'false'

        post api_v1_accounts_url,
             params: params,
             as: :json

        expect(response).to have_http_status(:not_found)
        ENV['ENABLE_ACCOUNT_SIGNUP'] = nil
      end
    end

    context 'when ENABLE_ACCOUNT_SIGNUP env variable is set to api_only' do
      it 'does not respond 404 on requests' do
        params = { account_name: 'test', email: email }
        ENV['ENABLE_ACCOUNT_SIGNUP'] = 'api_only'

        post api_v1_accounts_url,
             params: params,
             as: :json

        expect(response).not_to have_http_status(:not_found)
        ENV['ENABLE_ACCOUNT_SIGNUP'] = nil
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}' do
    let(:account) { create(:account) }
    let(:agent) { create(:user, account: account, role: :agent) }
    let(:user_without_access) { create(:user) }
    let(:admin) { create(:user, account: account, role: :administrator) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an unauthorized user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}",
            headers: user_without_access.create_new_auth_token

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when it is an authenticated user' do
      it 'shows an account' do
        get "/api/v1/accounts/#{account.id}",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include(account.name)
        expect(response.body).to include(account.locale)
        expect(response.body).to include(account.domain)
        expect(response.body).to include(account.support_email)
      end
    end
  end

  describe 'PUT /api/v1/accounts/{account.id}' do
    let(:account) { create(:account) }
    let(:agent) { create(:user, account: account, role: :agent) }
    let(:admin) { create(:user, account: account, role: :administrator) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        put "/api/v1/accounts/#{account.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an unauthorized user' do
      it 'returns unauthorized' do
        put "/api/v1/accounts/#{account.id}",
            headers: agent.create_new_auth_token

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      params = {
        name: 'New Name',
        locale: 'en',
        domain: 'example.com',
        support_email: 'care@example.com'
      }

      it 'modifies an account' do
        put "/api/v1/accounts/#{account.id}",
            params: params,
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(account.reload.name).to eq(params[:name])
        expect(account.reload.locale).to eq(params[:locale])
        expect(account.reload.domain).to eq(params[:domain])
        expect(account.reload.support_email).to eq(params[:support_email])
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/update_active_at' do
    let(:account) { create(:account) }
    let(:agent) { create(:user, account: account, role: :agent) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/update_active_at"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'modifies an account' do
        expect(agent.account_users.first.active_at).to eq(nil)
        post "/api/v1/accounts/#{account.id}/update_active_at",
             params: {},
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(agent.account_users.first.active_at).not_to eq(nil)
      end
    end
  end
end
