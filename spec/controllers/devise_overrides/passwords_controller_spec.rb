require 'rails_helper'

RSpec.describe 'DeviseOverrides::PasswordsController', type: :request do
  let(:account) { create(:account) }

  describe 'POST /auth/password' do
    context 'with regular user' do
      let!(:user) { create(:user, email: 'regular@example.com') }

      it 'allows password reset request' do
        post '/auth/password', params: { email: user.email }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['message']).to eq(I18n.t('messages.reset_password_success'))
      end
    end

    context 'with SAML user' do
      let!(:saml_user) { create(:user, email: 'saml@example.com', provider: 'saml') }

      it 'blocks password reset request' do
        post '/auth/password', params: { email: saml_user.email }

        expect(response).to have_http_status(:forbidden)
      end

      it 'returns proper error message' do
        post '/auth/password', params: { email: saml_user.email }

        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body['message']).to eq(I18n.t('messages.reset_password_saml_user'))
      end
    end

    context 'with non-existent user' do
      it 'returns not found error' do
        post '/auth/password', params: { email: 'nonexistent@example.com' }

        expect(response).to have_http_status(:not_found)
        expect(response.parsed_body['message']).to eq(I18n.t('messages.reset_password_failure'))
      end
    end

    context 'with blank email' do
      it 'allows the request to proceed normally' do
        post '/auth/password', params: { email: '' }

        expect(response).to have_http_status(:not_found)
        expect(response.parsed_body['message']).to eq(I18n.t('messages.reset_password_failure'))
      end
    end
  end
end
