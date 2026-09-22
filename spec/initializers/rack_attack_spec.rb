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

  describe 'throttle event logging' do
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
