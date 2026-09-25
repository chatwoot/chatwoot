require 'rails_helper'

# rubocop:disable RSpec/DescribeClass
describe 'Rack::Attack auth throttles' do
  let(:ip) { '203.0.113.7' }

  def throttle_key(name, env)
    Rack::Attack.throttles.fetch(name).block.call(Rack::Attack::Request.new(env))
  end

  def build_env(path, body, content_type)
    {
      'REQUEST_METHOD' => 'POST',
      'PATH_INFO' => path,
      'SCRIPT_NAME' => '',
      'QUERY_STRING' => '',
      'CONTENT_TYPE' => content_type,
      'CONTENT_LENGTH' => body.bytesize.to_s,
      'REMOTE_ADDR' => ip,
      'rack.input' => StringIO.new(body),
      'rack.url_scheme' => 'http',
      'action_dispatch.remote_ip' => ip
    }
  end

  def json_env(body, path = '/auth/sign_in')
    build_env(path, body.to_json, 'application/json')
  end

  def form_env(params, path = '/auth/sign_in')
    build_env(path, Rack::Utils.build_nested_query(params), 'application/x-www-form-urlencoded')
  end

  describe 'login/ip' do
    it 'counts form-encoded password sign-ins by ip' do
      expect(throttle_key('login/ip', form_env({ 'email' => 'a@b.com', 'password' => 'x' }))).to eq(ip)
    end

    it 'counts JSON password sign-ins by ip' do
      expect(throttle_key('login/ip', json_env({ email: 'a@b.com', password: 'x' }))).to eq(ip)
    end

    it 'skips form-encoded verification submissions carrying mfa_token' do
      expect(throttle_key('login/ip', form_env({ 'mfa_token' => 'tok', 'otp_code' => '123456' }))).to be_nil
    end

    it 'skips JSON verification submissions carrying mfa_token' do
      expect(throttle_key('login/ip', json_env({ mfa_token: 'tok', otp_code: '123456' }))).to be_nil
    end
  end

  describe 'login/email' do
    it 'keys JSON password sign-ins by normalized email' do
      key = throttle_key('login/email', json_env({ email: ' User@Example.COM ', password: 'x' }))
      expect(key).to eq('user@example.com')
    end

    it 'keys sign-ins that pass the email via request header' do
      env = build_env('/auth/sign_in', '{"password":"x"}', 'application/json')
      env['HTTP_EMAIL'] = ' User@Example.COM '
      expect(throttle_key('login/email', env)).to eq('user@example.com')
    end

    it 'skips JSON verification submissions carrying mfa_token' do
      expect(throttle_key('login/email', json_env({ mfa_token: 'tok', otp_code: '123456' }))).to be_nil
    end

    it 'skips requests without an email instead of sharing a blank key' do
      expect(throttle_key('login/email', json_env({ otp_code: '123456' }))).to be_nil
    end

    it 'skips a non-string email instead of raising a 500' do
      expect(throttle_key('login/email', json_env({ email: ['a@b.com'], password: 'x' }))).to be_nil
    end

    it 'skips malformed JSON bodies without raising' do
      env = build_env('/auth/sign_in', '{"email": broken', 'application/json')
      expect(throttle_key('login/email', env)).to be_nil
    end
  end

  describe 'malformed query strings' do
    it 'falls back to the per-ip throttle instead of raising on an over-nested query' do
      env = build_env('/auth/sign_in', '{}', 'application/json')
      env['QUERY_STRING'] = "a#{'[b]' * 200}=x"
      expect(throttle_key('login/ip', env)).to eq(ip)
    end
  end

  describe 'mfa_login/ip' do
    it 'counts JSON verification submissions by ip' do
      expect(throttle_key('mfa_login/ip', json_env({ mfa_token: 'tok', otp_code: '123456' }))).to eq(ip)
    end
  end

  describe 'mfa_login/token' do
    it 'keys JSON verification submissions by token' do
      expect(throttle_key('mfa_login/token', json_env({ mfa_token: 'tok', otp_code: '123456' }))).to eq('tok')
    end
  end

  describe 'reset_password/email' do
    it 'keys JSON requests by normalized email' do
      key = throttle_key('reset_password/email', json_env({ email: ' User@Example.COM ' }, '/auth/password'))
      expect(key).to eq('user@example.com')
    end

    it 'skips requests without an email instead of sharing a blank key' do
      expect(throttle_key('reset_password/email', json_env({ redirect_url: '/' }, '/auth/password'))).to be_nil
    end

    it 'ignores the email header, which this endpoint does not honor' do
      env = build_env('/auth/password', '{}', 'application/json')
      env['HTTP_EMAIL'] = 'victim@example.com'
      expect(throttle_key('reset_password/email', env)).to be_nil
    end
  end

  describe 'resend_confirmation/email' do
    it 'skips requests without an email instead of sharing a blank key' do
      expect(throttle_key('resend_confirmation/email', json_env({}, '/resend_confirmation'))).to be_nil
    end
  end

  describe 'API user throttles' do
    let(:env) { Rack::MockRequest.env_for('/api/v2/accounts/1/reports', 'REMOTE_ADDR' => ip) }

    it 'shares the reports key for legacy and bearer API tokens' do
      name = '/api/v2/accounts/:account_id/reports/user'
      expect(throttle_key(name, env.merge('HTTP_API_ACCESS_TOKEN' => 'api-token'))).to eq('api-token:1')
      expect(throttle_key(name, env.merge('HTTP_AUTHORIZATION' => 'bearer   api-token'))).to eq('api-token:1')
    end

    it 'keys reports drilldown by the bearer API token' do
      env = Rack::MockRequest.env_for('/api/v2/accounts/1/reports/drilldown', 'HTTP_AUTHORIZATION' => 'Bearer api-token')
      expect(throttle_key('/api/v2/accounts/:account_id/reports/drilldown/user', env)).to eq('api-token:1')
    end

    it 'keys conversation meta by the bearer API token' do
      env = Rack::MockRequest.env_for('/api/v1/accounts/1/conversations/meta', 'HTTP_AUTHORIZATION' => 'Bearer api-token')
      expect(throttle_key('/api/v1/accounts/:account_id/conversations/meta/user', env)).to eq('api-token:1')
    end

    it 'gives the bearer token precedence over other identity headers' do
      headers = { 'HTTP_AUTHORIZATION' => 'Bearer api-token', 'HTTP_UID' => 'other-user', 'HTTP_API_ACCESS_TOKEN' => 'other-token' }
      expect(throttle_key('/api/v2/accounts/:account_id/reports/user', env.merge(headers))).to eq('api-token:1')
    end

    it 'preserves dashboard UID keys with and without encoded bearer credentials' do
      credentials = { uid: 'user@example.com', client: 'client', 'access-token': 'session-token' }
      encoded = Base64.strict_encode64(credentials.to_json)
      name = '/api/v2/accounts/:account_id/reports/user'
      expect(throttle_key(name, env.merge('HTTP_UID' => credentials[:uid]))).to eq('user@example.com:1')
      expect(throttle_key(name, env.merge('HTTP_AUTHORIZATION' => "Bearer #{encoded}"))).to eq('user@example.com:1')
      expect(throttle_key(name, env.merge('HTTP_AUTHORIZATION' => "Bearer junk #{encoded}"))).to eq('user@example.com:1')
    end

    it 'skips missing and empty credentials' do
      name = '/api/v2/accounts/:account_id/reports/user'
      expect(throttle_key(name, env)).to be_nil
      expect(throttle_key(name, env.merge('HTTP_AUTHORIZATION' => 'Bearer', 'HTTP_API_ACCESS_TOKEN' => 'api-token'))).to be_nil
    end
  end

  describe 'throttle event logging' do
    it 'masks bearer tokens even when a UID header is supplied' do
      env = Rack::MockRequest.env_for('/api/v2/accounts/1/reports',
                                      'HTTP_AUTHORIZATION' => 'Bearer api-token-secret', 'HTTP_UID' => 'spoofed-user')
      request = Rack::Attack::Request.new(env)

      expect(Rails.logger).to receive(:warn).with(a_string_including('user_identifier: "api-t...[REDACTED]"'))
      ActiveSupport::Notifications.instrument('throttle.rack_attack', request: request)
    end

    it 'logs the dashboard UID for encoded bearer credentials' do
      credentials = { uid: 'user@example.com', client: 'client', 'access-token': 'session-token' }
      env = Rack::MockRequest.env_for('/api/v2/accounts/1/reports',
                                      'HTTP_AUTHORIZATION' => "Bearer #{Base64.strict_encode64(credentials.to_json)}")
      request = Rack::Attack::Request.new(env)

      expect(Rails.logger).to receive(:warn).with(a_string_including('user_identifier: "user@example.com"'))
      ActiveSupport::Notifications.instrument('throttle.rack_attack', request: request)
    end

    it 'logs which rule matched' do
      env = form_env({ 'email' => 'a@b.com', 'password' => 'x' })
      env['rack.attack.matched'] = 'login/ip'
      request = Rack::Attack::Request.new(env)

      expect(Rails.logger).to receive(:warn).with(a_string_including('matched_rule: "login/ip"'))
      ActiveSupport::Notifications.instrument('throttle.rack_attack', request: request)
    end
  end
end

# rubocop:enable RSpec/DescribeClass
