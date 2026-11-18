require 'rails_helper'

RSpec.describe 'Passwords API', type: :request do
  describe 'PUT /auth/password' do
    let(:account) { create(:account) }
    let!(:user) { create(:user, password: 'Test@123456', account: account) }

    def reset_token_for(user, sent_at: Time.current)
      raw, enc = Devise.token_generator.generate(User, :reset_password_token)
      user.update!(reset_password_token: enc, reset_password_sent_at: sent_at)
      raw
    end

    def reset_password(token, password: 'NewPassword1!')
      put user_password_path,
          params: { reset_password_token: token, password: password, password_confirmation: password },
          as: :json
    end

    it 'rejects a token sent before the reset window' do
      reset_password(reset_token_for(user, sent_at: 7.hours.ago))

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['message']).to eq('Invalid token')
      expect(response.headers['access-token']).to be_nil
      expect(user.reload.valid_password?('Test@123456')).to be true
    end

    context 'when the user signed up and has not confirmed their email' do
      let!(:user) { create(:user, password: 'Test@123456', account: account, skip_confirmation: false) }

      it 'rejects a token sent before the reset window' do
        reset_password(reset_token_for(user, sent_at: 7.hours.ago))

        expect(response).to have_http_status(:unprocessable_entity)
        expect(user.reload).not_to be_confirmed
      end
    end

    context 'when the user was invited and has not accepted yet' do
      let!(:user) do
        create(:user, password: 'Test@123456', account: account, inviter: create(:user, account: account), skip_confirmation: false)
      end

      it 'accepts an invitation token for days after it was sent' do
        reset_password(reset_token_for(user, sent_at: 2.days.ago))

        expect(response).to have_http_status(:success)
        expect(user.reload).to be_confirmed
      end

      it 'rejects an invitation token sent before the invitation window' do
        reset_password(reset_token_for(user, sent_at: 8.days.ago))

        expect(response).to have_http_status(:unprocessable_entity)
        expect(user.reload).not_to be_confirmed
      end

      it 'keeps the invitation usable after a rejected password' do
        token = reset_token_for(user, sent_at: 2.days.ago)

        reset_password(token, password: 'short')
        expect(response).to have_http_status(:unprocessable_entity)
        expect(user.reload).not_to be_confirmed

        reset_password(token)
        expect(response).to have_http_status(:success)
      end
    end

    it 'issues session tokens on successful reset' do
      account.enable_features!(:api_and_webhooks)
      reset_password(reset_token_for(user))

      expect(response).to have_http_status(:success)
      expect(response.headers['access-token']).to be_present
      expect(response.parsed_body.fetch('data')).to include(
        'access_token' => user.access_token.token,
        'pubsub_token' => user.reload.pubsub_token
      )
      expect(Current.user).to be_nil
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
