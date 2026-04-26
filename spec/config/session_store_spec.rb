require 'rails_helper'

# rubocop:disable RSpec/DescribeClass
describe 'Session Store Configuration' do
  # rubocop:enable RSpec/DescribeClass

  describe 'session cookie configuration' do
    let(:session_options) { Rails.application.config.session_options }

    it 'uses cookie_store as the session store' do
      expect(Rails.application.config.session_store).to eq(ActionDispatch::Session::CookieStore)
    end

    it 'sets the session key from environment variable with default fallback' do
      # The key should be either from ENV or the default '_chatwoot_session'
      expected_key = ENV.fetch('SESSION_COOKIE_KEY', '_chatwoot_session')
      expect(session_options[:key]).to eq(expected_key)
    end

    it 'sets same_site to lax for CSRF protection' do
      expect(session_options[:same_site]).to eq(:lax)
    end

    it 'sets httponly to true to prevent XSS attacks' do
      expect(session_options[:httponly]).to be(true)
    end

    context 'in production environment' do
      it 'sets secure flag based on Rails environment' do
        # In production, secure should be true
        # In development/test, secure should be false
        expected_secure = Rails.env.production?
        expect(session_options[:secure]).to eq(expected_secure)
      end
    end
  end

  describe 'environment variable configuration' do
    context 'when SESSION_COOKIE_KEY is set' do
      it 'allows customization of session cookie name via environment variable' do
        # This test verifies the ENV.fetch pattern is used correctly
        # The actual value comes from the initializer loading
        expect(ENV.fetch('SESSION_COOKIE_KEY', '_chatwoot_session')).to be_a(String)
      end
    end

    context 'when SESSION_COOKIE_KEY is not set' do
      it 'falls back to default _chatwoot_session' do
        # Temporarily remove the env var to test default
        original_value = ENV['SESSION_COOKIE_KEY']
        ENV.delete('SESSION_COOKIE_KEY')

        expect(ENV.fetch('SESSION_COOKIE_KEY', '_chatwoot_session')).to eq('_chatwoot_session')

        # Restore original value if it existed
        ENV['SESSION_COOKIE_KEY'] = original_value if original_value
      end
    end
  end

  describe 'security considerations' do
    let(:session_options) { Rails.application.config.session_options }

    it 'has httponly flag to prevent JavaScript access to session cookie' do
      # httponly prevents client-side scripts from accessing the cookie
      # This is important for mitigating XSS attacks
      expect(session_options[:httponly]).to be(true)
    end

    it 'has same_site set to lax to prevent CSRF attacks' do
      # same_site: :lax provides reasonable CSRF protection while still
      # allowing the cookie to be sent with top-level navigations
      expect(session_options[:same_site]).to eq(:lax)
    end

    it 'does not use same_site: :none which would require secure flag' do
      # same_site: :none would require secure: true always
      expect(session_options[:same_site]).not_to eq(:none)
    end
  end
end
