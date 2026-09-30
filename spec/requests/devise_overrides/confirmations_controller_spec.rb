require 'rails_helper'

RSpec.describe 'Confirmations API', type: :request do
  describe 'POST /auth/confirmation' do
    let(:account) { create(:account) }
    let(:user) { create(:user, account: account, skip_confirmation: false) }

    def confirm_user(user)
      post user_confirmation_path,
           params: { confirmation_token: user.confirmation_token },
           as: :json
    end

    it 'issues session tokens on successful confirmation' do
      confirm_user(user)

      expect(response).to have_http_status(:success)
      expect(response.headers['access-token']).to be_present
      expect(user.reload.confirmed?).to be true
    end

    context 'when account enforces MFA' do
      before do
        skip('Skipping since MFA is not configured in this environment') unless Chatwoot.encryption_configured?
        account.update!(enforce_mfa: true)
      end

      it 'confirms the user but withholds session tokens' do
        confirm_user(user)

        expect(response).to have_http_status(:success)
        expect(response.headers['access-token']).to be_nil
        expect(response.parsed_body['redirect_url']).to eq('/app/login')
        expect(user.reload.confirmed?).to be true
      end
    end

    context 'when the user is already enrolled in MFA' do
      before do
        skip('Skipping since MFA is not configured in this environment') unless Chatwoot.encryption_configured?
        user.enable_two_factor!
        user.update!(otp_required_for_login: true)
      end

      it 'confirms the user but withholds session tokens' do
        confirm_user(user)

        expect(response).to have_http_status(:success)
        expect(response.headers['access-token']).to be_nil
        expect(response.parsed_body['redirect_url']).to eq('/app/login')
        expect(user.reload.confirmed?).to be true
      end
    end
  end
end
