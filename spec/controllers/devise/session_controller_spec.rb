require 'rails_helper'

RSpec.describe 'Session', type: :request do
  describe 'GET /sign_in' do
    let!(:account) { create(:account) }

    context 'when it is invalid credentials' do
      it 'returns unauthorized' do
        params = { email: 'invalid@invalid.com', password: 'invalid' }

        post new_user_session_url,
             params: params,
             as: :json
        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to include('Invalid login credentials')
      end
    end

    context 'when the user is unconfirmed' do
      let!(:user) { create(:user, password: 'Password1!', account: account, skip_confirmation: false) }

      it 'returns an unconfirmed user error code' do
        params = { email: user.email, password: 'Password1!' }

        post new_user_session_url,
             params: params,
             as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body['error_code']).to eq('user_not_confirmed')
        expect(response.parsed_body['errors'].first).to include(user.email)
      end
    end

    context 'when it is valid credentials' do
      let!(:user) { create(:user, password: 'Password1!', account: account) }
      let!(:user_with_new_pwd) { create(:user, password: 'Password1!.><?', account: account) }

      it 'returns successful auth response' do
        params = { email: user.email, password: 'Password1!' }

        post new_user_session_url,
             params: params,
             as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include(user.email)
      end

      it 'returns successful auth response with new password special characters' do
        params = { email: user_with_new_pwd.email, password: 'Password1!.><?' }

        post new_user_session_url,
             params: params,
             as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include(user_with_new_pwd.email)
      end

      it 'returns the permission of the user' do
        params = { email: user.email, password: 'Password1!' }

        post new_user_session_url,
             params: params,
             as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['data']['accounts'].first['permissions']).to eq(['agent'])
      end

      it 'returns the Shopify billing route state for feature-enabled accounts' do
        shopify_account = create(
          :account,
          internal_attributes: {
            'billing_provider' => 'shopify',
            'signup_source' => 'shopify'
          },
          custom_attributes: {
            'subscription_status' => 'pending'
          }
        )
        shopify_account.enable_features!('shopify_integration')
        create(
          :integrations_hook,
          :shopify,
          account: shopify_account,
          reference_id: 'billing-test-store.myshopify.com'
        )
        shopify_user = create(:user, password: 'Password1!', account: shopify_account)
        allow(Shopify::FeatureGate).to receive(:enabled?).with(account: shopify_account).and_return(true)

        post new_user_session_url,
             params: { email: shopify_user.email, password: 'Password1!' },
             as: :json

        account_payload = response.parsed_body['data']['accounts'].first
        expect(account_payload).to include(
          'billing_provider' => 'shopify',
          'subscription_status' => 'pending',
          'shopify_integration' => true,
          'shopify_shop_domain' => 'billing-test-store.myshopify.com'
        )
      end
    end

    context 'when it is invalid sso auth token' do
      let!(:user) { create(:user, password: 'Password1!', account: account) }

      it 'returns unauthorized' do
        params = { email: user.email, sso_auth_token: SecureRandom.hex(32) }

        post new_user_session_url,
             params: params,
             as: :json
        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to include('Invalid login credentials')
      end
    end

    context 'when with valid sso auth token' do
      let!(:user) { create(:user, password: 'Password1!', account: account) }

      it 'returns successful auth response' do
        params = { email: user.email, sso_auth_token: user.generate_sso_auth_token }

        post new_user_session_url, params: params, as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include(user.email)

        # token won't work on a subsequent request
        post new_user_session_url, params: params, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /auth/sign_in' do
    it 'redirects to the frontend login page with error' do
      with_modified_env FRONTEND_URL: '' do
        get new_user_session_url

        expect(response).to redirect_to(%r{/app/login\?error=access-denied$})
      end
    end
  end
end
