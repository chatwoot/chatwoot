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

    context 'when it is valid credentials' do
      let!(:user) { create(:user, password: 'test1234', account: account) }

      it 'returns successful auth response' do
        params = { email: user.email, password: 'test1234' }

        post new_user_session_url,
             params: params,
             as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include(user.email)
      end
    end

    context 'when it is invalid sso auth token' do
      let!(:user) { create(:user, password: 'test1234', account: account) }

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
      let!(:user) { create(:user, password: 'test1234', account: account) }

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
end
