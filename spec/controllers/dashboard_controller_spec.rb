require 'rails_helper'

describe '/app/login', type: :request do
  context 'without DEFAULT_LOCALE' do
    it 'renders the dashboard' do
      get '/app/login'
      expect(response).to have_http_status(:success)
    end
  end

  context 'with DEFAULT_LOCALE' do
    it 'renders the dashboard' do
      with_modified_env DEFAULT_LOCALE: 'pt_BR' do
        get '/app/login'
        expect(response).to have_http_status(:success)
        expect(response.body).to include "selectedLocale: 'pt_BR'"
      end
    end
  end

  context 'with non-HTML format' do
    it 'returns not acceptable for JSON with error message' do
      get '/app/login', headers: { 'Accept' => 'application/json' }
      expect(response).to have_http_status(:not_acceptable)
      expect(response.parsed_body).to eq({ 'error' => 'Please use API routes instead of dashboard routes for JSON requests' })
    end
  end

  context 'with trusted proxy auth enabled' do
    let(:header) { 'Cf-Access-Authenticated-User-Email' }

    around do |example|
      with_modified_env(ENABLE_TRUSTED_PROXY_AUTH: 'true') { example.run }
    end

    it 'redirects an existing user to the login page with an sso token' do
      user = create(:user, email: 'agent+ops@example.com')

      get '/app/login', headers: { header => user.email }

      expect(response).to have_http_status(:redirect)
      query = Rack::Utils.parse_query(URI.parse(response.location).query)
      expect(CGI.unescape(query['email'])).to eq(user.email)
      expect(user.valid_sso_auth_token?(query['sso_auth_token'])).to be(true)
    end

    it 'double-encodes emails containing a literal percent sign' do
      user = create(:user)
      user.update_column(:email, 'agent%ops@example.com') # rubocop:disable Rails/SkipsModelValidations

      get '/app/login', headers: { header => user.email }

      query = Rack::Utils.parse_query(URI.parse(response.location).query)
      expect(query['email']).to eq('agent%25ops%40example.com')
      expect(CGI.unescape(query['email'])).to eq(user.email)
    end

    it 'confirms an unconfirmed invitee and rotates their password before issuing a token' do
      user = create(:user, skip_confirmation: false)
      old_password_digest = user.encrypted_password
      expect(user.reload.confirmed?).to be(false)

      get '/app/login', headers: { header => user.email }

      expect(response).to have_http_status(:redirect)
      user.reload
      expect(user.confirmed?).to be(true)
      expect(user.encrypted_password).not_to eq(old_password_digest)
    end

    it 'preserves the post-login continuation the dashboard router passed to the login page' do
      user = create(:user)
      redirect_url = "settings/integrations/shopify?shopify_pending_install=#{'a' * 32}"

      get '/app/login', params: { redirect_url: redirect_url, sso_account_id: '42' }, headers: { header => user.email }

      query = Rack::Utils.parse_query(URI.parse(response.location).query)
      expect(query).to include('redirect_url' => redirect_url, 'sso_account_id' => '42')
      expect(user.valid_sso_auth_token?(query['sso_auth_token'])).to be(true)
    end

    it 'drops continuation params that are not in the shapes the dashboard produces' do
      user = create(:user)

      get '/app/login', params: { redirect_url: 'https://evil.example.com', sso_account_id: 'abc' }, headers: { header => user.email }

      query = Rack::Utils.parse_query(URI.parse(response.location).query)
      expect(query.keys).to contain_exactly('email', 'sso_auth_token')
    end

    it 'renders the login page when no user matches the header' do
      get '/app/login', headers: { header => 'nobody@example.com' }

      expect(response).to have_http_status(:success)
    end

    it 'returns not acceptable for JSON requests instead of redirecting' do
      user = create(:user)

      get '/app/login', headers: { header => user.email, 'Accept' => 'application/json' }

      expect(response).to have_http_status(:not_acceptable)
    end

    it 'points the frontend logout redirect at the proxy logout endpoint' do
      get '/app/login'

      expect(response.body).to include('/cdn-cgi/access/logout')
    end
  end

  # Routes are loaded once on app start
  # hence Rails.application.reload_routes! is used in this spec
  # ref : https://stackoverflow.com/a/63584877/939299
  context 'with CW_API_ONLY_SERVER true' do
    it 'returns 404' do
      with_modified_env CW_API_ONLY_SERVER: 'true' do
        Rails.application.reload_routes!
        get '/app/login'
        expect(response).to have_http_status(:not_found)
      end
      Rails.application.reload_routes!
    end
  end
end
