require 'rails_helper'

RSpec.describe DeviseOverrides::SessionsController, type: :controller do
  include Devise::Test::ControllerHelpers

  before do
    request.env['devise.mapping'] = Devise.mappings[:user]
  end

  describe 'POST #create' do
    let(:user) { create(:user, password: 'Test@123456') }

    context 'with standard authentication' do
      it 'authenticates with valid credentials' do
        post :create, params: { email: user.email, password: 'Test@123456' }

        expect(response).to have_http_status(:success)
      end

      it 'rejects invalid credentials' do
        post :create, params: { email: user.email, password: 'wrong' }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with MFA authentication' do
      before do
        skip('Skipping since MFA is not configured in this environment') unless Chatwoot.encryption_configured?
        user.enable_two_factor!
        user.update!(otp_required_for_login: true)
      end

      it 'requires MFA verification after successful password authentication' do
        post :create, params: { email: user.email, password: 'Test@123456' }

        expect(response).to have_http_status(:partial_content)
        json_response = response.parsed_body
        expect(json_response['mfa_required']).to be(true)
        expect(json_response['mfa_token']).to be_present
      end

      it 'does not return authentication tokens before MFA verification' do
        post :create, params: { email: user.email, password: 'Test@123456' }

        expect(response).to have_http_status(:partial_content)

        # Check that no authentication headers are present
        expect(response.headers['access-token']).to be_nil
        expect(response.headers['uid']).to be_nil
        expect(response.headers['client']).to be_nil
        expect(response.headers['Authorization']).to be_nil

        # Check that no bearer token is present in any form
        response.headers.each do |key, value|
          expect(value.to_s).not_to include('Bearer') if key.downcase.include?('auth')
        end

        json_response = response.parsed_body
        expect(json_response['data']).to be_nil
      end

      context 'when verifying MFA' do
        let(:mfa_token) { Mfa::TokenService.new(user: user).generate_token }

        it 'authenticates with valid OTP' do
          post :create, params: {
            mfa_token: mfa_token,
            otp_code: user.current_otp
          }

          expect(response).to have_http_status(:success)
        end

        it 'authenticates with valid backup code' do
          backup_codes = user.generate_backup_codes!

          post :create, params: {
            mfa_token: mfa_token,
            backup_code: backup_codes.first
          }

          expect(response).to have_http_status(:success)
        end

        it 'rejects invalid OTP' do
          post :create, params: {
            mfa_token: mfa_token,
            otp_code: '000000'
          }

          expect(response).to have_http_status(:bad_request)
          expect(response.parsed_body['error']).to eq(I18n.t('errors.mfa.invalid_code'))
        end

        it 'rejects invalid backup code' do
          user.generate_backup_codes!

          post :create, params: {
            mfa_token: mfa_token,
            backup_code: 'invalid'
          }

          expect(response).to have_http_status(:bad_request)
          expect(response.parsed_body['error']).to eq(I18n.t('errors.mfa.invalid_code'))
        end

        it 'rejects expired MFA token' do
          expired_token = JWT.encode(
            { user_id: user.id, exp: 1.minute.ago.to_i },
            Rails.application.secret_key_base,
            'HS256'
          )

          post :create, params: {
            mfa_token: expired_token,
            otp_code: user.current_otp
          }

          expect(response).to have_http_status(:unauthorized)
          expect(response.parsed_body['error']).to eq(I18n.t('errors.mfa.invalid_token'))
        end

        it 'requires either OTP or backup code' do
          post :create, params: { mfa_token: mfa_token }

          expect(response).to have_http_status(:bad_request)
          expect(response.parsed_body['error']).to eq(I18n.t('errors.mfa.invalid_code'))
        end
      end
    end

    context 'with SSO authentication' do
      it 'authenticates with valid SSO token' do
        sso_token = user.generate_sso_auth_token

        post :create, params: {
          email: user.email,
          sso_auth_token: sso_token
        }

        expect(response).to have_http_status(:success)
      end

      it 'rejects invalid SSO token' do
        post :create, params: {
          email: user.email,
          sso_auth_token: 'invalid'
        }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET #new' do
    it 'redirects to frontend login page' do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('FRONTEND_URL', nil).and_return('/frontend')

      get :new

      expect(response).to redirect_to('/frontend/app/login?error=access-denied')
    end
  end
end
