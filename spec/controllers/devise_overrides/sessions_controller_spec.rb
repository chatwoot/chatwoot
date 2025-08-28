require 'rails_helper'

RSpec.describe 'DeviseOverrides::SessionsController', type: :request do
  let(:account) { create(:account) }

  describe 'POST /auth/sign_in' do
    context 'with regular user' do
      let!(:user) { create(:user, email: 'regular@example.com', password: 'Password123!') }

      it 'allows password login' do
        post '/auth/sign_in', params: {
          email: user.email,
          password: 'Password123!'
        }

        expect(response).to have_http_status(:ok)
        expect(response.headers['access-token']).to be_present
      end
    end

    context 'with SAML user' do
      let!(:saml_user) { create(:user, email: 'saml@example.com', provider: 'saml', password: 'Password123!') }

      it 'blocks password login' do
        post '/auth/sign_in', params: {
          email: saml_user.email,
          password: 'Password123!'
        }

        expect(response).to have_http_status(:unauthorized)
        expect(response.headers['access-token']).to be_blank
      end

      it 'returns proper error message' do
        post '/auth/sign_in', params: {
          email: saml_user.email,
          password: 'Password123!'
        }

        expect(response).to have_http_status(:unauthorized)
        response_body = response.parsed_body
        expect(response_body['success']).to be false
        expect(response_body['errors']).to include(I18n.t('messages.login_saml_user'))
      end

      context 'with SSO token' do
        it 'allows login via SSO token' do
          sso_token = saml_user.generate_sso_auth_token

          post '/auth/sign_in', params: {
            email: saml_user.email,
            sso_auth_token: sso_token
          }

          expect(response).to have_http_status(:ok)
          expect(response.headers['access-token']).to be_present
        end
      end
    end

    context 'with invalid credentials' do
      it 'returns unauthorized error' do
        post '/auth/sign_in', params: {
          email: 'invalid@example.com',
          password: 'wrongpassword'
        }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with blank email' do
      it 'allows the request to proceed normally' do
        post '/auth/sign_in', params: {
          email: '',
          password: 'somepassword'
        }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
