require 'rails_helper'

RSpec.describe 'OAuth Authorization Server Metadata', type: :request do
  before do
    InstallationConfig.where(name: 'OAUTH_PROVIDER_ENABLED').delete_all
    InstallationConfig.create!(name: 'OAUTH_PROVIDER_ENABLED', value: true)
  end

  after { GlobalConfig.clear_cache }

  describe 'GET /.well-known/oauth-authorization-server' do
    it 'returns 404 when the provider is disabled' do
      InstallationConfig.find_by(name: 'OAUTH_PROVIDER_ENABLED').update!(value: false)

      get '/.well-known/oauth-authorization-server'

      expect(response).to have_http_status(:not_found)
    end

    it 'describes the endpoints on the installation URL' do
      with_modified_env FRONTEND_URL: 'https://support.example.com' do
        get '/.well-known/oauth-authorization-server'
      end

      expect(response).to have_http_status(:success)
      expect(response.parsed_body).to include(
        'issuer' => 'https://support.example.com',
        'authorization_endpoint' => 'https://support.example.com/oauth/authorize',
        'token_endpoint' => 'https://support.example.com/oauth/token',
        'registration_endpoint' => 'https://support.example.com/oauth/register',
        'revocation_endpoint' => 'https://support.example.com/oauth/revoke'
      )
    end

    it 'advertises only public clients, the code flow and S256' do
      get '/.well-known/oauth-authorization-server'

      expect(response.parsed_body).to include(
        'response_types_supported' => ['code'],
        'grant_types_supported' => %w[authorization_code refresh_token],
        'token_endpoint_auth_methods_supported' => ['none'],
        'code_challenge_methods_supported' => ['S256'],
        'scopes_supported' => %w[conversations:read contacts:read conversations:write messages:write contacts:write]
      )
    end
  end

  describe 'GET /oauth/authorize' do
    it 'redirects the browser to the dashboard consent screen with the query intact' do
      get '/oauth/authorize', params: { client_id: 'abc', state: 'a b', redirect_uri: 'https://chatgpt.com/cb' }

      expect(response).to have_http_status(:found)
      expect(response.location).to end_with('/app/oauth/authorize?client_id=abc&state=a+b&redirect_uri=https%3A%2F%2Fchatgpt.com%2Fcb')
    end
  end
end
