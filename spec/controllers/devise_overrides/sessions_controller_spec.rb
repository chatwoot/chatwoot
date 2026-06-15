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

  describe 'session limit enforcement' do
    before { stub_const('DeviseOverrides::SessionsController::MAX_SESSIONS', 5) }

    let(:user) { create(:user, password: 'Test@123456') }
    let(:browser_ua) { 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2.1 Safari/605.1.15' }
    let(:mobile_ua) { 'okhttp/4.9.3' }

    def seed_token(client_id, expiry_offset_days: 30, with_session: true)
      user.tokens = user.tokens.merge(
        client_id => { 'token' => 'x', 'expiry' => (Time.current + expiry_offset_days.days).to_i }
      )
      user.save!
      user.user_sessions.create!(client_id: client_id, last_activity_at: Time.current) if with_session
    end

    def login_params
      { email: user.email, password: 'Test@123456' }
    end

    context 'when under the limit' do
      it 'allows login without intervention' do
        request.env['HTTP_USER_AGENT'] = browser_ua
        3.times { |i| seed_token("c#{i}", expiry_offset_days: 30) }

        post :create, params: login_params

        expect(response).to have_http_status(:success)
      end

      it 'does not count expired tokens toward the cap' do
        request.env['HTTP_USER_AGENT'] = browser_ua
        # 3 expired + 2 active = 5 raw entries, but only 2 active
        3.times { |i| seed_token("expired#{i}", expiry_offset_days: -1, with_session: false) }
        2.times { |i| seed_token("active#{i}", expiry_offset_days: 30) }

        post :create, params: login_params

        expect(response).to have_http_status(:success)
      end
    end

    context 'when at the limit from a browser with full tracking' do
      before do
        request.env['HTTP_USER_AGENT'] = browser_ua
        5.times { |i| seed_token("c#{i}", expiry_offset_days: 30) }
      end

      it 'returns 409 with the session list (picker)' do
        post :create, params: login_params

        expect(response).to have_http_status(:conflict)
        body = response.parsed_body
        expect(body['sessions_limit_reached']).to be true
        expect(body['sessions'].size).to eq(5)
      end

      it 'does not create a new session row' do
        expect { post :create, params: login_params }.not_to change(user.user_sessions, :count)
      end
    end

    context 'when at the limit from a non-browser client' do
      before do
        request.env['HTTP_USER_AGENT'] = mobile_ua
        5.times { |i| seed_token("c#{i}", expiry_offset_days: 30 + i, with_session: false) }
      end

      it 'silently evicts the oldest token and lets login proceed' do
        post :create, params: login_params

        expect(response).to have_http_status(:success)
        expect(user.reload.tokens.keys).not_to include('c0')
      end
    end

    context 'when at the limit but tracking is partial (legacy tokens present)' do
      before do
        request.env['HTTP_USER_AGENT'] = browser_ua
        # one tracked, four legacy (no user_session rows)
        seed_token('tracked', expiry_offset_days: 60, with_session: true)
        4.times { |i| seed_token("legacy#{i}", expiry_offset_days: 10 + i, with_session: false) }
      end

      it 'silent-evicts instead of showing a partial picker' do
        post :create, params: login_params

        expect(response).to have_http_status(:success)
      end

      it 'drops an untracked token first, keeping the tracked session alive' do
        post :create, params: login_params

        tokens = user.reload.tokens.keys
        expect(tokens).to include('tracked')
        # legacy0 expires soonest -> evict_oldest_token picks it
        expect(tokens).not_to include('legacy0')
      end
    end

    context 'when at the limit with full tracking (no legacy gap)' do
      before do
        request.env['HTTP_USER_AGENT'] = mobile_ua
        # Five tracked sessions, varying activity timestamps
        5.times do |i|
          seed_token("tracked#{i}", expiry_offset_days: 30)
          user.user_sessions.find_by(client_id: "tracked#{i}").update!(last_activity_at: (5 - i).days.ago)
        end
      end

      it 'evicts the oldest tracked session by last_activity_at' do
        post :create, params: login_params

        expect(response).to have_http_status(:success)
        # tracked0 had the oldest last_activity_at (5 days ago)
        expect(user.reload.tokens.keys).not_to include('tracked0')
        expect(user.user_sessions.exists?(client_id: 'tracked0')).to be false
      end
    end

    context 'with revoke_session_id during login' do
      before do
        request.env['HTTP_USER_AGENT'] = browser_ua
        5.times { |i| seed_token("c#{i}", expiry_offset_days: 30) }
      end

      it 'revokes the chosen session and proceeds with login' do
        target = user.user_sessions.find_by(client_id: 'c2')

        post :create, params: login_params.merge(revoke_session_id: target.id)

        expect(response).to have_http_status(:success)
        expect(user.reload.tokens.keys).not_to include('c2')
        expect(user.user_sessions.exists?(id: target.id)).to be false
      end
    end

    context 'with revoke_all_sessions during login' do
      before do
        request.env['HTTP_USER_AGENT'] = browser_ua
        5.times { |i| seed_token("c#{i}", expiry_offset_days: 30) }
      end

      it 'wipes all sessions and tokens, then proceeds with login' do
        post :create, params: login_params.merge(revoke_all_sessions: true)

        expect(response).to have_http_status(:success)
        expect(user.reload.tokens.keys).not_to include('c0', 'c1', 'c2', 'c3', 'c4')
        # the new login adds one fresh token
        expect(user.tokens.keys.size).to eq(1)
      end
    end

    context 'with a successful login' do
      before { request.env['HTTP_USER_AGENT'] = browser_ua }

      it 'creates a UserSession row for the new client_id' do
        expect { post :create, params: login_params }.to change(user.user_sessions, :count).by(1)

        session = user.user_sessions.last
        expect(session.browser_name).to eq('Safari')
        expect(session.platform_name).to eq('macOS')
      end
    end
  end

  describe 'impersonation SSO login' do
    let(:user) { create(:user, password: 'Test@123456') }
    let(:browser_ua) { 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2.1 Safari/605.1.15' }

    before { request.env['HTTP_USER_AGENT'] = browser_ua }

    it 'does not create a UserSession row for impersonation login' do
      sso_token = user.generate_sso_auth_token(impersonation: true)

      expect do
        post :create, params: { email: user.email, sso_auth_token: sso_token }
      end.not_to change(user.user_sessions, :count)

      expect(response).to have_http_status(:success)
    end

    it 'creates a short-lived token for impersonation login' do
      sso_token = user.generate_sso_auth_token(impersonation: true)

      post :create, params: { email: user.email, sso_auth_token: sso_token }

      expect(response).to have_http_status(:success)
      token_entry = user.reload.tokens.values.last
      # 2-day lifespan: expiry should be within ~3 days from now (token creation + lifespan)
      expect(token_entry['expiry']).to be < (3.days.from_now).to_i
    end

    it 'creates a normal UserSession row for regular SSO login' do
      sso_token = user.generate_sso_auth_token

      expect do
        post :create, params: { email: user.email, sso_auth_token: sso_token }
      end.to change(user.user_sessions, :count).by(1)
    end

    it 'preserves the impersonation token when target user is at the device cap' do
      allow(DeviseTokenAuth).to receive(:max_number_of_devices).and_return(5)
      5.times do |i|
        user.tokens["existing#{i}"] = { 'token' => 'x', 'expiry' => (Time.current + (30 + i).days).to_i }
      end
      user.save!
      sso_token = user.generate_sso_auth_token(impersonation: true)

      post :create, params: { email: user.email, sso_auth_token: sso_token }

      expect(response).to have_http_status(:success)
      new_client_id = response.headers['client']
      expect(user.reload.tokens.keys).to include(new_client_id)
      expect(user.tokens.size).to eq(5)
    end
  end
end
