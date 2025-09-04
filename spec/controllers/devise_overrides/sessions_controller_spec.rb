require 'rails_helper'

describe DeviseOverrides::SessionsController do
  let(:user) { create(:user, password: 'Test@123456') }

  describe 'POST #create' do
    context 'when user has MFA disabled' do
      it 'logs in successfully with valid credentials' do
        post :create, params: { email: user.email, password: 'Test@123456' }
        expect(response).to have_http_status(:success)
      end
    end

    context 'when user has MFA enabled' do
      before do
        user.enable_two_factor!
        user.update!(otp_required_for_login: true)
      end

      it 'returns mfa_required response with valid credentials' do
        post :create, params: { email: user.email, password: 'Test@123456' }

        expect(response).to have_http_status(:partial_content)
        json_response = response.parsed_body
        expect(json_response['mfa_required']).to be_truthy
        expect(json_response['mfa_token']).to be_present
      end
    end

    context 'when verifying MFA with valid OTP' do
      let(:user) { create(:user, password: 'Test@123456') }
      let(:mfa_token) { Mfa::TokenService.new(user: user).generate_token }

      before do
        user.enable_two_factor!
        user.update!(otp_required_for_login: true)
      end

      it 'logs in successfully' do
        valid_otp = user.current_otp

        post :create, params: { mfa_token: mfa_token, otp_code: valid_otp }

        expect(response).to have_http_status(:success)
      end
    end

    context 'when verifying MFA with invalid OTP' do
      let(:user) { create(:user, password: 'Test@123456') }
      let(:mfa_token) { Mfa::TokenService.new(user: user).generate_token }

      before do
        user.enable_two_factor!
        user.update!(otp_required_for_login: true)
      end

      it 'returns error' do
        post :create, params: { mfa_token: mfa_token, otp_code: '000000' }

        expect(response).to have_http_status(:bad_request)
        json_response = response.parsed_body
        expect(json_response['error']).to eq(I18n.t('errors.mfa.invalid_code'))
      end
    end

    context 'when verifying MFA with valid backup code' do
      let(:user) { create(:user, password: 'Test@123456') }
      let(:mfa_token) { Mfa::TokenService.new(user: user).generate_token }
      let(:backup_codes) { user.generate_backup_codes! }

      before do
        user.enable_two_factor!
        user.update!(otp_required_for_login: true)
      end

      it 'logs in successfully' do
        valid_backup_code = backup_codes.first

        post :create, params: { mfa_token: mfa_token, backup_code: valid_backup_code }

        expect(response).to have_http_status(:success)
      end
    end

    context 'when verifying MFA with invalid backup code' do
      let(:user) { create(:user, password: 'Test@123456') }
      let(:mfa_token) { Mfa::TokenService.new(user: user).generate_token }

      before do
        user.enable_two_factor!
        user.update!(otp_required_for_login: true)
        user.generate_backup_codes!
      end

      it 'returns error' do
        post :create, params: { mfa_token: mfa_token, backup_code: 'invalid' }

        expect(response).to have_http_status(:bad_request)
        json_response = response.parsed_body
        expect(json_response['error']).to eq(I18n.t('errors.mfa.invalid_code'))
      end
    end

    context 'when verifying MFA with expired token' do
      let(:user) { create(:user, password: 'Test@123456') }
      let(:expired_token) do
        payload = { user_id: user.id, exp: 1.minute.ago.to_i }
        JWT.encode(payload, Rails.application.secret_key_base, 'HS256')
      end

      before do
        user.enable_two_factor!
        user.update!(otp_required_for_login: true)
      end

      it 'returns unauthorized error' do
        valid_otp = user.current_otp

        post :create, params: { mfa_token: expired_token, otp_code: valid_otp }

        expect(response).to have_http_status(:unauthorized)
        json_response = response.parsed_body
        expect(json_response['error']).to eq(I18n.t('errors.mfa.invalid_token'))
      end
    end

    context 'when verifying MFA with invalid token' do
      let(:user) { create(:user, password: 'Test@123456') }

      before do
        user.enable_two_factor!
        user.update!(otp_required_for_login: true)
      end

      it 'returns unauthorized error' do
        post :create, params: { mfa_token: 'invalid_token', otp_code: user.current_otp }

        expect(response).to have_http_status(:unauthorized)
        json_response = response.parsed_body
        expect(json_response['error']).to eq(I18n.t('errors.mfa.invalid_token'))
      end
    end

    context 'when verifying MFA without credentials' do
      let(:user) { create(:user, password: 'Test@123456') }
      let(:mfa_token) { Mfa::TokenService.new(user: user).generate_token }

      before do
        user.enable_two_factor!
        user.update!(otp_required_for_login: true)
      end

      it 'returns error' do
        post :create, params: { mfa_token: mfa_token }

        expect(response).to have_http_status(:bad_request)
        json_response = response.parsed_body
        expect(json_response['error']).to eq(I18n.t('errors.mfa.invalid_code'))
      end
    end
  end
end
