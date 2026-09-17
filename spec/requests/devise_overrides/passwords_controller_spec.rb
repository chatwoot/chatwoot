require 'rails_helper'

RSpec.describe 'Passwords API', type: :request do
  describe 'PUT /auth/password' do
    let(:account) { create(:account) }
    let!(:user) { create(:user, password: 'Test@123456', account: account) }

    def reset_token_for(user)
      raw, enc = Devise.token_generator.generate(User, :reset_password_token)
      user.update!(reset_password_token: enc, reset_password_sent_at: Time.current)
      raw
    end

    def reset_password(token)
      put user_password_path,
          params: { reset_password_token: token, password: 'NewPassword1!', password_confirmation: 'NewPassword1!' },
          as: :json
    end

    it 'issues session tokens on successful reset' do
      reset_password(reset_token_for(user))

      expect(response).to have_http_status(:success)
      expect(response.headers['access-token']).to be_present
    end

    context 'when account enforces MFA' do
      before do
        skip('Skipping since MFA is not configured in this environment') unless Chatwoot.encryption_configured?
        account.update!(enforce_mfa: true)
      end

      it 'resets the password but withholds session tokens' do
        reset_password(reset_token_for(user))

        expect(response).to have_http_status(:success)
        expect(response.headers['access-token']).to be_nil
        expect(response.parsed_body['redirect_url']).to eq('/app/login')
        expect(user.reload.valid_password?('NewPassword1!')).to be true
      end

      it 'withholds tokens for enrolled users so reset cannot bypass their otp' do
        user.enable_two_factor!
        user.update!(otp_required_for_login: true)

        reset_password(reset_token_for(user))

        expect(response).to have_http_status(:success)
        expect(response.headers['access-token']).to be_nil
        expect(response.parsed_body['redirect_url']).to eq('/app/login')
        expect(user.reload.valid_password?('NewPassword1!')).to be true
      end
    end
  end
end
