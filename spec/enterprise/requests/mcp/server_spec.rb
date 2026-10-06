require 'rails_helper'

RSpec.describe 'MCP server', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:application) { Doorkeeper::Application.create!(name: 'ChatGPT', redirect_uri: 'https://chatgpt.com/callback', confidential: false) }
  let(:access_token) do
    Doorkeeper::AccessToken.create!(application: application, resource_owner_id: user.id, account_id: account.id,
                                    scopes: 'conversations:read', expires_in: 2.hours)
  end
  let(:headers) do
    { 'Authorization' => "Bearer #{access_token.plaintext_token}", 'Content-Type' => 'application/json',
      'Accept' => 'application/json, text/event-stream' }
  end
  let(:initialize_request) do
    { jsonrpc: '2.0', id: 1, method: 'initialize',
      params: { protocolVersion: '2025-06-18', capabilities: {}, clientInfo: { name: 'spec', version: '1.0' } } }
  end

  before do
    InstallationConfig.where(name: 'OAUTH_PROVIDER_ENABLED').delete_all
    InstallationConfig.create!(name: 'OAUTH_PROVIDER_ENABLED', value: true)
  end

  after { GlobalConfig.clear_cache }

  describe 'POST /mcp' do
    it 'returns 404 when the OAuth provider is disabled' do
      request_headers = headers
      InstallationConfig.find_by(name: 'OAUTH_PROVIDER_ENABLED').update!(value: false)

      post '/mcp', params: initialize_request.to_json, headers: request_headers

      expect(response).to have_http_status(:not_found)
    end

    it 'challenges a request without a token and points to the resource metadata' do
      with_modified_env FRONTEND_URL: 'https://support.example.com' do
        post '/mcp', params: initialize_request.to_json, headers: headers.except('Authorization')
      end

      expect(response).to have_http_status(:unauthorized)
      expect(response.headers['WWW-Authenticate']).to eq(
        'Bearer resource_metadata="https://support.example.com/.well-known/oauth-protected-resource/mcp"'
      )
    end

    it 'rejects a revoked token' do
      access_token.revoke

      post '/mcp', params: initialize_request.to_json, headers: headers

      expect(response).to have_http_status(:unauthorized)
    end

    it 'rejects an expired token' do
      access_token.update!(created_at: 3.hours.ago)

      post '/mcp', params: initialize_request.to_json, headers: headers

      expect(response).to have_http_status(:unauthorized)
    end

    it 'rejects a dashboard API access token' do
      post '/mcp', params: initialize_request.to_json, headers: headers.merge('Authorization' => "Bearer #{user.access_token.token}")

      expect(response).to have_http_status(:unauthorized)
    end

    it 'rejects a token for a suspended account' do
      account.update!(status: :suspended)

      post '/mcp', params: initialize_request.to_json, headers: headers

      expect(response).to have_http_status(:unauthorized)
    end

    it 'answers the initialize request' do
      post '/mcp', params: initialize_request.to_json, headers: headers

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['result']).to include('protocolVersion' => '2025-06-18')
      expect(response.parsed_body.dig('result', 'serverInfo', 'name')).to eq('chatwoot')
      expect(response.parsed_body.dig('result', 'capabilities')).to have_key('tools')
    end

    it 'does not issue a session' do
      post '/mcp', params: initialize_request.to_json, headers: headers

      expect(response.headers['Mcp-Session-Id']).to be_nil
    end
  end

  describe 'GET /mcp' do
    it 'refuses to open an event stream' do
      get '/mcp', headers: headers.merge('Accept' => 'text/event-stream')

      expect(response).to have_http_status(:method_not_allowed)
    end
  end

  describe 'GET /.well-known/oauth-protected-resource' do
    it 'returns 404 when the OAuth provider is disabled' do
      InstallationConfig.find_by(name: 'OAUTH_PROVIDER_ENABLED').update!(value: false)

      get '/.well-known/oauth-protected-resource'

      expect(response).to have_http_status(:not_found)
    end

    it 'names the MCP endpoint and its authorization server' do
      with_modified_env FRONTEND_URL: 'https://support.example.com' do
        get '/.well-known/oauth-protected-resource'
      end

      expect(response).to have_http_status(:success)
      expect(response.parsed_body).to include(
        'resource' => 'https://support.example.com/mcp',
        'authorization_servers' => ['https://support.example.com'],
        'bearer_methods_supported' => ['header'],
        'scopes_supported' => %w[conversations:read contacts:read conversations:write messages:write contacts:write]
      )
    end

    it 'serves the same document at the path-specific URL' do
      get '/.well-known/oauth-protected-resource/mcp'

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['resource']).to end_with('/mcp')
    end
  end
end
