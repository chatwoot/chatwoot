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

      it 'authenticates with valid credentials supplied as request headers' do
        request.headers['email'] = user.email
        request.headers['password'] = 'Test@123456'

        post :create

        expect(response).to have_http_status(:success)
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

      it 'requires MFA verification when credentials arrive as request headers' do
        request.headers['email'] = user.email
        request.headers['password'] = 'Test@123456'

        post :create

        expect(response).to have_http_status(:partial_content)
        expect(response.parsed_body['mfa_required']).to be(true)
        expect(response.headers['access-token']).to be_nil
      end

      it 'does not let header credentials override body credentials' do
        request.headers['email'] = user.email
        request.headers['password'] = 'Test@123456'

        post :create, params: { email: user.email, password: 'wrong-password' }

        expect(response).not_to have_http_status(:partial_content)
        expect(response.headers['access-token']).to be_nil
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
            otp_code: 'invalid'
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

        it 'rejects mfa verification for a locked account' do
          user.lock_access!

          post :create, params: { mfa_token: mfa_token, otp_code: user.current_otp }

          expect(response).to have_http_status(:unauthorized)
          expect(response.parsed_body['error_code']).to eq('account_locked')
        end

        it 'counts wrong otp codes toward the lockout threshold' do
          expect do
            post :create, params: { mfa_token: mfa_token, otp_code: '000000' }
          end.to change { user.reload.failed_attempts }.by(1)
        end

        it 'locks the account when wrong otp codes exhaust the threshold' do
          user.update!(failed_attempts: Devise.maximum_attempts - 1)

          post :create, params: { mfa_token: mfa_token, otp_code: '000000' }

          expect(user.reload.access_locked?).to be true
        end

        it 'returns the locked error on the attempt that crosses the threshold' do
          user.update!(failed_attempts: Devise.maximum_attempts - 1)

          post :create, params: { mfa_token: mfa_token, otp_code: '000000' }

          expect(response).to have_http_status(:unauthorized)
          expect(response.parsed_body['error_code']).to eq('account_locked')
        end

        it 'does not immediately relock an expired lock on one wrong otp' do
          user.update!(failed_attempts: Devise.maximum_attempts, locked_at: (Devise.unlock_in + 1.hour).ago)

          post :create, params: { mfa_token: mfa_token, otp_code: '000000' }

          expect(user.reload.access_locked?).to be false
          expect(user.failed_attempts).to eq(1)
        end

        it 'resets the counter and clears a stale lock on successful mfa sign-in' do
          user.update!(failed_attempts: 5, locked_at: (Devise.unlock_in + 1.hour).ago)

          post :create, params: { mfa_token: mfa_token, otp_code: user.current_otp }

          expect(response).to have_http_status(:success)
          expect(user.reload.failed_attempts).to eq(0)
          expect(user.locked_at).to be_nil
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

      it 'signs in and unlocks a locked account via sso' do
        user.update!(failed_attempts: Devise.maximum_attempts)
        user.lock_access!
        sso_token = user.generate_sso_auth_token

        post :create, params: {
          email: user.email,
          sso_auth_token: sso_token
        }

        expect(response).to have_http_status(:success)
        expect(user.reload.access_locked?).to be false
        expect(user.failed_attempts).to eq(0)
      end
    end
  end

  describe 'account lockout' do
    let(:password) { 'Test@123456' }
    let!(:user) { create(:user, password: password) }

    def attempt_sign_in(pwd)
      post :create, params: { email: user.email, password: pwd }
    end

    it 'locks the account after the configured number of failed attempts and says so on that attempt' do
      (Devise.maximum_attempts - 1).times { attempt_sign_in('wrong-password') }
      attempt_sign_in('wrong-password')

      expect(user.reload.access_locked?).to be true
      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body['error_code']).to eq('account_locked')
      expect(response.parsed_body['errors'].first).to eq(I18n.t('devise.failure.locked'))
    end

    it 'rejects the correct password while locked with the locked error' do
      Devise.maximum_attempts.times { attempt_sign_in('wrong-password') }
      attempt_sign_in(password)

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body['error_code']).to eq('account_locked')
    end

    it 'does not lock before the threshold and resets the counter on success' do
      (Devise.maximum_attempts - 1).times { attempt_sign_in('wrong-password') }
      expect(user.reload.access_locked?).to be false

      attempt_sign_in(password)

      expect(response).to have_http_status(:success)
      expect(user.reload.failed_attempts).to eq(0)
    end

    it 'unlocks automatically after the lockout period' do
      Devise.maximum_attempts.times { attempt_sign_in('wrong-password') }

      travel_to(Devise.unlock_in.from_now + 1.minute) do
        attempt_sign_in(password)

        expect(response).to have_http_status(:success)
        expect(user.reload.access_locked?).to be false
      end
    end

    it 'notifies the user once when the account locks' do
      expect do
        (Devise.maximum_attempts + 2).times { attempt_sign_in('wrong-password') }
      end.to have_enqueued_mail(SecurityMailer, :account_locked).once
    end

    it 'does not notify again for a relock within the dedupe window' do
      Devise.maximum_attempts.times { attempt_sign_in('wrong-password') }

      travel_to(2.hours.from_now) do
        expect do
          Devise.maximum_attempts.times { attempt_sign_in('wrong-password') }
        end.not_to have_enqueued_mail(SecurityMailer, :account_locked)
      end
    end

    it 'notifies again for a new lock cycle after the dedupe window' do
      Devise.maximum_attempts.times { attempt_sign_in('wrong-password') }

      travel_to(25.hours.from_now) do
        expect do
          Devise.maximum_attempts.times { attempt_sign_in('wrong-password') }
        end.to have_enqueued_mail(SecurityMailer, :account_locked).once
      end
    end
  end

  describe 'ip abuse blocking' do
    let(:password) { 'Test@123456' }
    let!(:user) { create(:user, password: password) }
    let(:spec_ip) { '203.0.113.10' }

    before do
      GlobalConfig.clear_cache
      allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
      request.remote_addr = spec_ip
      Redis::Alfred.delete(format(Redis::RedisKeys::AUTH_FAILED_EMAILS_PER_IP, ip: spec_ip))
      Redis::Alfred.delete(format(Redis::RedisKeys::AUTH_ABUSE_BLOCKED_IP, ip: spec_ip))
    end

    after { GlobalConfig.clear_cache }

    it 'records failed attempts and blocks the ip after distinct-email threshold' do
      5.times do |i|
        post :create, params: { email: "u#{i}@example.com", password: 'wrong-password' }
      end

      post :create, params: { email: user.email, password: password }

      expect(response).to have_http_status(:too_many_requests)
      expect(response.parsed_body['error_code']).to eq('sign_in_blocked')
      expect(response.parsed_body['errors'].first).to eq(I18n.t('errors.sign_in.blocked'))
    end

    it 'does not count successful sign-ins' do
      5.times { post :create, params: { email: user.email, password: password } }

      post :create, params: { email: user.email, password: password }

      expect(response).to have_http_status(:success)
    end

    it 'does not block below the threshold' do
      4.times do |i|
        post :create, params: { email: "u#{i}@example.com", password: 'wrong-password' }
      end

      post :create, params: { email: user.email, password: password }

      expect(response).to have_http_status(:success)
    end

    it 'still allows sso sign-in from a blocked ip' do
      5.times do |i|
        post :create, params: { email: "u#{i}@example.com", password: 'wrong-password' }
      end
      sso_token = user.generate_sso_auth_token

      post :create, params: { email: user.email, sso_auth_token: sso_token }

      expect(response).to have_http_status(:success)
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
    around { |example| with_modified_env('MAX_USER_SESSIONS' => '5') { example.run } }

    let(:user) { create(:user, password: 'Test@123456') }
    let(:session_limit) { ENV.fetch('MAX_USER_SESSIONS', '5').to_i }
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
        # Raw token count reaches the cap, but three tokens are expired
        3.times { |i| seed_token("expired#{i}", expiry_offset_days: -1, with_session: false) }
        (session_limit - 3).times { |i| seed_token("active#{i}", expiry_offset_days: 30) }

        post :create, params: login_params

        expect(response).to have_http_status(:success)
      end
    end

    context 'when at the limit from a browser with full tracking' do
      before do
        request.env['HTTP_USER_AGENT'] = browser_ua
        session_limit.times { |i| seed_token("c#{i}", expiry_offset_days: 30) }
      end

      it 'returns 409 with the session list (picker)' do
        post :create, params: login_params

        expect(response).to have_http_status(:conflict)
        body = response.parsed_body
        expect(body['sessions_limit_reached']).to be true
        expect(body['sessions'].size).to eq(session_limit)
      end

      it 'does not create a new session row' do
        expect { post :create, params: login_params }.not_to change(user.user_sessions, :count)
      end
    end

    context 'when at the limit from a non-browser client' do
      before do
        request.env['HTTP_USER_AGENT'] = mobile_ua
        session_limit.times { |i| seed_token("c#{i}", expiry_offset_days: 30 + i, with_session: false) }
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
        # One tracked session, with the remaining tokens having no user_session rows
        seed_token('tracked', expiry_offset_days: 60, with_session: true)
        (session_limit - 1).times { |i| seed_token("legacy#{i}", expiry_offset_days: 10 + i, with_session: false) }
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
        # Tracked sessions with varying activity timestamps
        session_limit.times do |i|
          seed_token("tracked#{i}", expiry_offset_days: 30)
          user.user_sessions.find_by(client_id: "tracked#{i}").update!(last_activity_at: (session_limit - i).days.ago)
        end
      end

      it 'evicts the oldest tracked session by last_activity_at' do
        post :create, params: login_params

        expect(response).to have_http_status(:success)
        # tracked0 has the oldest last_activity_at
        expect(user.reload.tokens.keys).not_to include('tracked0')
        expect(user.user_sessions.exists?(client_id: 'tracked0')).to be false
      end
    end

    context 'with revoke_session_id during login' do
      before do
        request.env['HTTP_USER_AGENT'] = browser_ua
        session_limit.times { |i| seed_token("c#{i}", expiry_offset_days: 30) }
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
        session_limit.times { |i| seed_token("c#{i}", expiry_offset_days: 30) }
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
