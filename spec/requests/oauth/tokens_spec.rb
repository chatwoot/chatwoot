require 'rails_helper'

RSpec.describe 'OAuth Tokens', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:redirect_uri) { 'https://chatgpt.com/connector/oauth/callback' }
  let(:application) { Doorkeeper::Application.create!(name: 'ChatGPT', redirect_uri: redirect_uri, confidential: false) }
  let(:code_verifier) { 'a-code-verifier-that-is-long-enough-to-be-valid-0123456789' }
  let(:code_challenge) { Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier), padding: false) }
  let(:code) do
    post '/api/v1/oauth/authorization',
         params: { client_id: application.uid, redirect_uri: redirect_uri, response_type: 'code', scope: 'conversations:read',
                   code_challenge: code_challenge, code_challenge_method: 'S256', account_id: account.id },
         headers: user.create_new_auth_token
    Rack::Utils.parse_query(URI.parse(response.parsed_body['redirect_uri']).query)['code']
  end
  let(:token_params) do
    { grant_type: 'authorization_code', code: code, client_id: application.uid, redirect_uri: redirect_uri, code_verifier: code_verifier }
  end

  before do
    InstallationConfig.where(name: 'OAUTH_PROVIDER_ENABLED').delete_all
    InstallationConfig.create!(name: 'OAUTH_PROVIDER_ENABLED', value: true)
  end

  after { GlobalConfig.clear_cache }

  describe 'POST /oauth/token' do
    it 'returns 404 when the provider is disabled' do
      params = token_params
      InstallationConfig.find_by(name: 'OAUTH_PROVIDER_ENABLED').update!(value: false)

      post '/oauth/token', params: params

      expect(response).to have_http_status(:not_found)
    end

    it 'exchanges a code for an access token and a refresh token' do
      post '/oauth/token', params: token_params

      expect(response).to have_http_status(:success)
      expect(response.parsed_body).to include('token_type' => 'Bearer', 'scope' => 'conversations:read')
      expect(response.parsed_body['access_token']).to be_present
      expect(response.parsed_body['refresh_token']).to be_present
    end

    it 'binds the token to the user and the account from the consent' do
      post '/oauth/token', params: token_params

      token = Doorkeeper::AccessToken.by_token(response.parsed_body['access_token'])
      expect(token).to have_attributes(resource_owner_id: user.id, account_id: account.id, application_id: application.id)
    end

    it 'does not store the tokens in plain text' do
      post '/oauth/token', params: token_params

      stored = Doorkeeper::AccessToken.last
      expect(stored.read_attribute(:token)).not_to eq(response.parsed_body['access_token'])
      expect(stored.read_attribute(:refresh_token)).not_to eq(response.parsed_body['refresh_token'])
    end

    it 'rejects a wrong code verifier' do
      post '/oauth/token', params: token_params.merge(code_verifier: 'a-different-verifier-that-is-long-enough-0123456789')

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body['error']).to eq('invalid_grant')
    end

    it 'rejects a request without a code verifier' do
      post '/oauth/token', params: token_params.except(:code_verifier)

      expect(response).to have_http_status(:bad_request)
      expect(Doorkeeper::AccessToken.count).to eq(0)
    end

    it 'rejects a code that was already used' do
      post '/oauth/token', params: token_params
      post '/oauth/token', params: token_params

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body['error']).to eq('invalid_grant')
    end

    it 'rejects a code presented by another client' do
      other = Doorkeeper::Application.create!(name: 'Other', redirect_uri: redirect_uri, confidential: false)

      post '/oauth/token', params: token_params.merge(client_id: other.uid)

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body['error']).to eq('invalid_grant')
    end

    it 'exchanges a refresh token for a new token on the same account' do
      post '/oauth/token', params: token_params
      first = response.parsed_body

      post '/oauth/token', params: { grant_type: 'refresh_token', refresh_token: first['refresh_token'], client_id: application.uid }

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['access_token']).not_to eq(first['access_token'])
      expect(Doorkeeper::AccessToken.by_token(response.parsed_body['access_token']).account_id).to eq(account.id)
      expect(Doorkeeper::AccessToken.by_token(first['access_token'])).to be_revoked
    end

    it 'rejects a refresh token that was already used' do
      post '/oauth/token', params: token_params
      refresh_params = { grant_type: 'refresh_token', refresh_token: response.parsed_body['refresh_token'], client_id: application.uid }

      post '/oauth/token', params: refresh_params
      post '/oauth/token', params: refresh_params

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body['error']).to eq('invalid_grant')
    end

    it 'rejects the client credentials grant' do
      post '/oauth/token', params: { grant_type: 'client_credentials', client_id: application.uid }

      expect(response).to have_http_status(:bad_request)
      expect(Doorkeeper::AccessToken.count).to eq(0)
    end
  end

  describe 'POST /oauth/revoke' do
    it 'revokes the access token' do
      post '/oauth/token', params: token_params
      access_token = response.parsed_body['access_token']

      post '/oauth/revoke', params: { token: access_token, client_id: application.uid }

      expect(response).to have_http_status(:success)
      expect(Doorkeeper::AccessToken.by_token(access_token)).to be_revoked
    end
  end
end
