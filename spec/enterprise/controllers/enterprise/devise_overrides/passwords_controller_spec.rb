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

  describe 'PUT /auth/password' do
    let!(:user) { create(:user, password: 'Test@123456', account: account) }

    it 'revokes trusted devices on reset' do
      raw, enc = Devise.token_generator.generate(User, :reset_password_token)
      user.update!(reset_password_token: enc, reset_password_sent_at: Time.current)

      expect do
        put user_password_path,
            params: { reset_password_token: raw, password: 'NewPassword1!', password_confirmation: 'NewPassword1!' },
            as: :json
      end.to change { user.reload.device_trust_version }.by(1)
    end
  end
end
