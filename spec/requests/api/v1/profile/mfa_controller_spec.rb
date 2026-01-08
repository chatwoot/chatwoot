require 'rails_helper'

RSpec.describe 'MFA API', type: :request do
  before do
    skip('Skipping since MFA is not configured in this environment') unless Chatwoot.encryption_configured?
    allow(Chatwoot).to receive(:mfa_enabled?).and_return(true)
  end

  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, password: 'Test@123456') }

  describe 'GET /api/v1/profile/mfa' do
    context 'when 2FA is disabled' do
      it 'returns MFA disabled status' do
        get '/api/v1/profile/mfa',
            headers: user.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['enabled']).to be_falsey
        expect(json_response['backup_codes_generated']).to be_falsey
      end
    end

    context 'when 2FA is enabled' do
      before do
        user.enable_two_factor!
        user.update!(otp_required_for_login: true)
      end

      it 'returns MFA enabled status' do
        get '/api/v1/profile/mfa',
            headers: user.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['enabled']).to be_truthy
      end

      context 'with backup codes generated' do
        before do
          user.generate_backup_codes!
        end

        it 'indicates backup codes are generated' do
          get '/api/v1/profile/mfa',
              headers: user.create_new_auth_token,
              as: :json

          expect(response).to have_http_status(:success)
          json_response = response.parsed_body
          expect(json_response['backup_codes_generated']).to be_truthy
        end
      end
    end
  end

  describe 'POST /api/v1/profile/mfa' do
    context 'when 2FA is not enabled' do
      it 'enables 2FA and returns QR code URL' do
        post '/api/v1/profile/mfa',
             headers: user.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['provisioning_url']).not_to be_nil
        expect(json_response['provisioning_url']).to include('otpauth://totp')
        expect(json_response['secret']).not_to be_nil

        user.reload
        expect(user.otp_secret).not_to be_nil
      end
    end

    context 'when 2FA is already enabled' do
      before do
        user.enable_two_factor!
        user.update!(otp_required_for_login: true)
      end

      it 'returns error message' do
        post '/api/v1/profile/mfa',
             headers: user.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = response.parsed_body
        expect(json_response['error']).to eq(I18n.t('errors.mfa.already_enabled'))
      end
    end
  end

  describe 'POST /api/v1/profile/mfa/verify' do
    before do
      user.enable_two_factor!
    end

    context 'with valid OTP code' do
      it 'verifies and confirms 2FA setup with backup codes' do
        otp_code = user.current_otp

        post '/api/v1/profile/mfa/verify',
             params: { otp_code: otp_code },
             headers: user.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['enabled']).to be_truthy
        expect(json_response['backup_codes']).to be_an(Array)
        expect(json_response['backup_codes'].length).to eq(10)

        user.reload
        expect(user.otp_required_for_login).to be_truthy
        expect(user.otp_backup_codes).not_to be_nil
      end
    end

    context 'with invalid OTP code' do
      it 'returns error message' do
        post '/api/v1/profile/mfa/verify',
             params: { otp_code: '000000' },
             headers: user.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = response.parsed_body
        expect(json_response['error']).to eq(I18n.t('errors.mfa.invalid_code'))
      end
    end

    context 'when 2FA is already verified' do
      before do
        user.update!(otp_required_for_login: true)
      end

      it 'returns already enabled error' do
        post '/api/v1/profile/mfa/verify',
             params: { otp_code: user.current_otp },
             headers: user.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = response.parsed_body
        expect(json_response['error']).to eq(I18n.t('errors.mfa.already_enabled'))
      end
    end
  end

  describe 'DELETE /api/v1/profile/mfa' do
    context 'when 2FA is enabled' do
      before do
        user.enable_two_factor!
        user.update!(otp_required_for_login: true)
        user.generate_backup_codes!
      end

      context 'with valid password and OTP' do
        it 'disables 2FA successfully' do
          otp_code = user.current_otp

          delete '/api/v1/profile/mfa',
                 params: { password: 'Test@123456', otp_code: otp_code },
                 headers: user.create_new_auth_token,
                 as: :json

          expect(response).to have_http_status(:success)
          json_response = response.parsed_body
          expect(json_response['enabled']).to be_falsey

          user.reload
          expect(user.otp_required_for_login).to be_falsey
          expect(user.otp_secret).to be_nil
          expect(user.otp_backup_codes).to be_blank
        end
      end

      context 'with invalid password' do
        it 'returns error message' do
          otp_code = user.current_otp

          delete '/api/v1/profile/mfa',
                 params: { password: 'wrong_password', otp_code: otp_code },
                 headers: user.create_new_auth_token,
                 as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          json_response = response.parsed_body
          expect(json_response['error']).to include('Invalid')
        end
      end

      context 'with invalid OTP' do
        it 'returns error message' do
          delete '/api/v1/profile/mfa',
                 params: { password: 'Test@123456', otp_code: '000000' },
                 headers: user.create_new_auth_token,
                 as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          json_response = response.parsed_body
          expect(json_response['error']).to include('Invalid')
        end
      end
    end

    context 'when 2FA is not enabled' do
      it 'returns not enabled error' do
        delete '/api/v1/profile/mfa',
               params: { password: 'Test@123456', otp_code: '123456' },
               headers: user.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = response.parsed_body
        expect(json_response['error']).to eq(I18n.t('errors.mfa.not_enabled'))
      end
    end
  end

  describe 'POST /api/v1/profile/mfa/backup_codes' do
    context 'when 2FA is enabled' do
      before do
        user.enable_two_factor!
        user.update!(otp_required_for_login: true)
      end

      context 'with valid OTP' do
        it 'generates new backup codes' do
          otp_code = user.current_otp

          post '/api/v1/profile/mfa/backup_codes',
               params: { otp_code: otp_code },
               headers: user.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:success)
          json_response = response.parsed_body
          expect(json_response['backup_codes']).to be_an(Array)
          expect(json_response['backup_codes'].length).to eq(10)
        end
      end

      context 'with invalid OTP' do
        it 'returns error message' do
          post '/api/v1/profile/mfa/backup_codes',
               params: { otp_code: '000000' },
               headers: user.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          json_response = response.parsed_body
          expect(json_response['error']).to eq(I18n.t('errors.mfa.invalid_code'))
        end
      end
    end

    context 'when 2FA is not enabled' do
      it 'returns not enabled error' do
        post '/api/v1/profile/mfa/backup_codes',
             params: { otp_code: '123456' },
             headers: user.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = response.parsed_body
        expect(json_response['error']).to eq(I18n.t('errors.mfa.not_enabled'))
      end
    end
  end
end
