require 'rails_helper'

RSpec.describe 'Enterprise Passwords Controller', type: :request do
  let!(:account) { create(:account) }

  describe 'POST /auth/password' do
    context 'with SAML user email' do
      let!(:saml_user) { create(:user, email: 'saml@example.com', provider: 'saml', account: account) }

      it 'prevents password reset and returns forbidden with custom error message' do
        params = { email: saml_user.email, redirect_url: 'http://test.host' }

        post user_password_path, params: params, as: :json

        expect(response).to have_http_status(:forbidden)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be(false)
        expect(json_response['errors']).to include(I18n.t('messages.reset_password_saml_user'))
      end
    end

    context 'with non-SAML user email' do
      let!(:regular_user) { create(:user, email: 'regular@example.com', provider: 'email', account: account) }

      it 'allows password reset for non-SAML users' do
        params = { email: regular_user.email, redirect_url: 'http://test.host' }

        post user_password_path, params: params, as: :json

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to be_present
      end
    end
  end
end
