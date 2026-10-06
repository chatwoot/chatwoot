require 'rails_helper'

# Walks the path an MCP client takes, from an unauthenticated call to a tool result.
RSpec.describe 'MCP OAuth flow', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }
  let(:redirect_uri) { 'https://chatgpt.com/connector/oauth/callback' }
  let(:code_verifier) { 'a-code-verifier-that-is-long-enough-to-be-valid-0123456789' }
  let(:mcp_headers) { { 'Content-Type' => 'application/json', 'Accept' => 'application/json, text/event-stream' } }
  let(:tool_call) do
    { jsonrpc: '2.0', id: 1, method: 'tools/call', params: { name: 'list_conversations', arguments: {} } }.to_json
  end

  before do
    InstallationConfig.where(name: 'OAUTH_PROVIDER_ENABLED').delete_all
    InstallationConfig.create!(name: 'OAUTH_PROVIDER_ENABLED', value: true)
    create(:inbox_member, inbox: inbox, user: agent)
  end

  after { GlobalConfig.clear_cache }

  it 'takes a client from the 401 challenge to a tool result' do
    conversation = create(:conversation, account: account, inbox: inbox)

    post '/mcp', params: tool_call, headers: mcp_headers
    resource_metadata_url = response.headers['WWW-Authenticate'][/resource_metadata="([^"]+)"/, 1]

    get URI.parse(resource_metadata_url).path
    resource_metadata = response.parsed_body

    get '/.well-known/oauth-authorization-server'
    server_metadata = response.parsed_body
    expect(resource_metadata['authorization_servers']).to eq([server_metadata['issuer']])

    post URI.parse(server_metadata['registration_endpoint']).path, params: { client_name: 'ChatGPT', redirect_uris: [redirect_uri] }, as: :json
    client_id = response.parsed_body['client_id']

    post '/api/v1/oauth/authorization',
         params: { client_id: client_id, redirect_uri: redirect_uri, response_type: 'code', state: 'client-state',
                   scope: resource_metadata['scopes_supported'].join(' '), account_id: account.id, code_challenge_method: 'S256',
                   code_challenge: Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier), padding: false) },
         headers: agent.create_new_auth_token
    code = Rack::Utils.parse_query(URI.parse(response.parsed_body['redirect_uri']).query)['code']

    post URI.parse(server_metadata['token_endpoint']).path,
         params: { grant_type: 'authorization_code', code: code, client_id: client_id, redirect_uri: redirect_uri, code_verifier: code_verifier,
                   resource: resource_metadata['resource'] }
    access_token = response.parsed_body['access_token']

    post '/mcp', params: tool_call, headers: mcp_headers.merge('Authorization' => "Bearer #{access_token}")

    expect(response).to have_http_status(:success)
    expect(response.parsed_body.dig('result', 'structuredContent', 'conversations').pluck('id')).to eq([conversation.display_id])
  end

  it 'stops serving the token once the user leaves the account' do
    application = Doorkeeper::Application.create!(name: 'ChatGPT', redirect_uri: redirect_uri, confidential: false)
    token = Doorkeeper::AccessToken.create!(application: application, resource_owner_id: agent.id, account_id: account.id,
                                            scopes: 'conversations:read', expires_in: 2.hours)

    account.account_users.find_by(user_id: agent.id).destroy!
    post '/mcp', params: tool_call, headers: mcp_headers.merge('Authorization' => "Bearer #{token.plaintext_token}")

    expect(response).to have_http_status(:unauthorized)
  end
end
