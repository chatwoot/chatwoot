require 'rails_helper'

RSpec.describe 'OAuth Authorizations API', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:auth_headers) { user.create_new_auth_token }
  let(:redirect_uri) { 'https://chatgpt.com/connector/oauth/callback' }
  let(:application) { Doorkeeper::Application.create!(name: 'ChatGPT', redirect_uri: redirect_uri, confidential: false) }
  let(:code_challenge) { Base64.urlsafe_encode64(Digest::SHA256.digest('a-code-verifier'), padding: false) }
  let(:oauth_params) do
    {
      client_id: application.uid,
      redirect_uri: redirect_uri,
      response_type: 'code',
      scope: 'conversations:read messages:write',
      state: 'client-state',
      code_challenge: code_challenge,
      code_challenge_method: 'S256'
    }
  end

  before do
    InstallationConfig.where(name: 'OAUTH_PROVIDER_ENABLED').delete_all
    InstallationConfig.create!(name: 'OAUTH_PROVIDER_ENABLED', value: true)
  end

  after { GlobalConfig.clear_cache }

  describe 'GET /api/v1/oauth/authorization' do
    it 'returns 404 when the provider is disabled' do
      InstallationConfig.find_by(name: 'OAUTH_PROVIDER_ENABLED').update!(value: false)

      get '/api/v1/oauth/authorization', params: oauth_params, headers: auth_headers

      expect(response).to have_http_status(:not_found)
    end

    it 'returns 401 without a dashboard session' do
      get '/api/v1/oauth/authorization', params: oauth_params

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 401 for an API access token' do
      get '/api/v1/oauth/authorization', params: oauth_params, headers: { api_access_token: user.access_token.token }

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns the client name and the requested scopes' do
      get '/api/v1/oauth/authorization', params: oauth_params, headers: auth_headers

      expect(response).to have_http_status(:success)
      expect(response.parsed_body).to include('client_name' => 'ChatGPT', 'scope' => 'conversations:read messages:write')
    end

    it 'falls back to the default scopes when none are requested' do
      get '/api/v1/oauth/authorization', params: oauth_params.except(:scope), headers: auth_headers

      expect(response.parsed_body['scope']).to eq('conversations:read contacts:read')
    end

    it 'rejects an unknown client' do
      get '/api/v1/oauth/authorization', params: oauth_params.merge(client_id: 'unknown'), headers: auth_headers

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body['error']).to eq('invalid_client')
    end

    it 'rejects a redirect URI that is not registered' do
      get '/api/v1/oauth/authorization', params: oauth_params.merge(redirect_uri: 'https://evil.example.com/callback'), headers: auth_headers

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body['error']).to eq('invalid_redirect_uri')
    end

    it 'rejects a request without a PKCE challenge' do
      get '/api/v1/oauth/authorization', params: oauth_params.except(:code_challenge, :code_challenge_method), headers: auth_headers

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body['error']).to eq('invalid_request')
    end

    it 'rejects the plain PKCE method' do
      get '/api/v1/oauth/authorization', params: oauth_params.merge(code_challenge_method: 'plain'), headers: auth_headers

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body['error']).to eq('invalid_code_challenge_method')
    end

    it 'rejects a scope the server does not define' do
      get '/api/v1/oauth/authorization', params: oauth_params.merge(scope: 'admin'), headers: auth_headers

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body['error']).to eq('invalid_scope')
    end
  end

  describe 'POST /api/v1/oauth/authorization' do
    it 'returns 401 without a dashboard session' do
      post '/api/v1/oauth/authorization', params: oauth_params.merge(account_id: account.id)

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 422 without an account' do
      post '/api/v1/oauth/authorization', params: oauth_params, headers: auth_headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(Doorkeeper::AccessGrant.count).to eq(0)
    end

    it 'returns 422 for an account the user does not belong to' do
      post '/api/v1/oauth/authorization', params: oauth_params.merge(account_id: create(:account).id), headers: auth_headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(Doorkeeper::AccessGrant.count).to eq(0)
    end

    it 'returns a redirect URI that carries the code and the state' do
      post '/api/v1/oauth/authorization', params: oauth_params.merge(account_id: account.id), headers: auth_headers

      expect(response).to have_http_status(:success)
      redirect = URI.parse(response.parsed_body['redirect_uri'])
      query = Rack::Utils.parse_query(redirect.query)
      expect(redirect.to_s).to start_with(redirect_uri)
      expect(query['code']).to be_present
      expect(query['state']).to eq('client-state')
    end

    it 'binds the grant to the user, the account and the scopes' do
      post '/api/v1/oauth/authorization', params: oauth_params.merge(account_id: account.id), headers: auth_headers

      grant = Doorkeeper::AccessGrant.last
      expect(grant).to have_attributes(resource_owner_id: user.id, account_id: account.id, application_id: application.id)
      expect(grant.scopes.to_a).to eq(%w[conversations:read messages:write])
    end

    it 'does not issue a code for an unregistered redirect URI' do
      post '/api/v1/oauth/authorization',
           params: oauth_params.merge(account_id: account.id, redirect_uri: 'https://evil.example.com/callback'),
           headers: auth_headers

      expect(response).to have_http_status(:bad_request)
      expect(Doorkeeper::AccessGrant.count).to eq(0)
    end
  end

  describe 'DELETE /api/v1/oauth/authorization' do
    it 'returns a redirect URI that carries the access_denied error' do
      delete '/api/v1/oauth/authorization', params: oauth_params, headers: auth_headers

      query = Rack::Utils.parse_query(URI.parse(response.parsed_body['redirect_uri']).query)
      expect(query).to include('error' => 'access_denied', 'state' => 'client-state')
      expect(Doorkeeper::AccessGrant.count).to eq(0)
    end

    it 'does not redirect to an unregistered redirect URI' do
      delete '/api/v1/oauth/authorization', params: oauth_params.merge(redirect_uri: 'https://evil.example.com/callback'), headers: auth_headers

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body).not_to have_key('redirect_uri')
    end
  end
end
