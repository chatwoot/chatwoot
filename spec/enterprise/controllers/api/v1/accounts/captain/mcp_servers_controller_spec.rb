require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::Captain::McpServers', type: :request do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:base_url) { "/api/v1/accounts/#{account.id}/captain/mcp_servers" }
  let(:server) do
    Captain::McpServer.create!(account: account, assistant: assistant, name: 'Invoicely', url: 'https://mcp.example.com/mcp',
                               auth_type: 'token', auth_config: { 'token' => 'secret' })
  end
  let(:definition) do
    { 'name' => 'get_customer', 'description' => 'Look up', 'input_schema' => { 'type' => 'object' }, 'read_only' => true }
  end

  before { account.enable_features!(Captain::McpServer::FEATURE_FLAG) }

  def json_response
    JSON.parse(response.body, symbolize_names: true)
  end

  it 'answers 403 while the account does not have MCP servers' do
    account.disable_features!(Captain::McpServer::FEATURE_FLAG)

    get base_url, params: { assistant_id: assistant.id }, headers: admin.create_new_auth_token, as: :json

    expect(response).to have_http_status(:forbidden)
    expect(json_response[:error]).to eq(I18n.t('captain.mcp_server.disabled'))
  end

  it 'lets an agent list servers but not change them' do
    server

    get base_url, params: { assistant_id: assistant.id }, headers: agent.create_new_auth_token, as: :json
    expect(response).to have_http_status(:success)
    expect(json_response[:payload].map { |item| item[:id] }).to eq([server.id])

    delete "#{base_url}/#{server.id}", params: { assistant_id: assistant.id }, headers: agent.create_new_auth_token, as: :json
    expect(response).to have_http_status(:unauthorized)
    expect(server.reload).to be_persisted
  end

  it 'does not find a server through another account' do
    other_account = create(:account)
    other_account.enable_features!(Captain::McpServer::FEATURE_FLAG)
    other_admin = create(:user, account: other_account, role: :administrator)
    other_assistant = create(:captain_assistant, account: other_account)

    get "/api/v1/accounts/#{other_account.id}/captain/mcp_servers/#{server.id}", params: { assistant_id: other_assistant.id },
                                                                                 headers: other_admin.create_new_auth_token, as: :json

    expect(response).to have_http_status(:not_found)
  end

  describe 'POST create' do
    it 'saves the server and never returns the token' do
      post base_url, params: { assistant_id: assistant.id,
                               mcp_server: { name: 'Invoicely', url: 'https://mcp.example.com/mcp', auth_type: 'token',
                                             auth_config: { token: 'secret' } } },
                     headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(response.body).not_to include('secret')
      expect(Captain::McpServer.last.auth_config['token']).to eq('secret')
    end

    it 'answers 422 with the reason for a URL it cannot use' do
      post base_url, params: { assistant_id: assistant.id, mcp_server: { name: 'Bad', url: 'https://user:pass@mcp.example.com/mcp' } },
                     headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response[:message]).to include('cannot contain a username or password')
    end
  end

  describe 'PATCH update' do
    it 'keeps the stored token when the edit sends none' do
      patch "#{base_url}/#{server.id}", params: { assistant_id: assistant.id, mcp_server: { name: 'Renamed', auth_config: { token: '' } } },
                                        headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(server.reload).to have_attributes(name: 'Renamed')
      expect(server.auth_config['token']).to eq('secret')
    end

    it 'never lets an edit change the URL or the sign-in type' do
      patch "#{base_url}/#{server.id}",
            params: { assistant_id: assistant.id, mcp_server: { url: 'https://evil.example.com/mcp', auth_type: 'none' } },
            headers: admin.create_new_auth_token, as: :json

      expect(server.reload).to have_attributes(url: 'https://mcp.example.com/mcp', auth_type: 'token')
    end
  end

  describe 'GET live_tools' do
    let(:connection) { instance_double(Captain::Mcp::Connection) }

    before { allow(Captain::Mcp::Connection).to receive(:new).and_return(connection) }

    it 'marks each live tool as approved or changed, and lists the approved tools the server dropped' do
      server.sync_tools({ 'get_customer' => {}, 'gone' => {} }, { 'get_customer' => definition, 'gone' => definition.merge('name' => 'gone') })
      allow(connection).to receive(:track_status).and_yield
      allow(connection).to receive(:tool_definitions).and_return([definition.merge('description' => 'Changed')])

      get "#{base_url}/#{server.id}/live_tools", params: { assistant_id: assistant.id }, headers: admin.create_new_auth_token, as: :json

      expect(json_response[:payload].map { |tool| tool.slice(:name, :approved, :changed) })
        .to eq([{ name: 'get_customer', approved: true, changed: true }])
      expect(json_response[:missing]).to eq(['gone'])
    end

    it 'answers 422 with the reason when the server fails' do
      allow(connection).to receive(:track_status).and_raise(Faraday::ConnectionFailed, 'connection refused')

      get "#{base_url}/#{server.id}/live_tools", params: { assistant_id: assistant.id }, headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response[:error]).to eq('connection refused')
    end
  end

  it 'answers 422 for a sign-in link on a server that does not use OAuth' do
    get "#{base_url}/#{server.id}/authorization_url", params: { assistant_id: assistant.id }, headers: admin.create_new_auth_token, as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(json_response[:error]).to eq(I18n.t('captain.mcp_server.not_oauth'))
  end

  describe 'POST discover' do
    it 'answers 422 with the reason for a URL it cannot use' do
      post "#{base_url}/discover", params: { assistant_id: assistant.id, url: 'http://mcp.example.com/mcp' },
                                   headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response[:error]).to include('must use HTTPS protocol')
    end

    it 'answers 422 when the server rejects the token the admin gave' do
      discovery = instance_double(Captain::Mcp::DiscoveryService)
      allow(Captain::Mcp::DiscoveryService).to receive(:new).and_return(discovery)
      allow(discovery).to receive(:perform).and_raise(RubyLLM::UnauthorizedError)

      post "#{base_url}/discover", params: { assistant_id: assistant.id, url: 'https://mcp.example.com/mcp', token: 'wrong' },
                                   headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response[:error]).to eq(I18n.t('captain.mcp_server.token_rejected'))
    end
  end

  it 'deletes a server with its approved tools' do
    server.sync_tools({ 'get_customer' => {} }, { 'get_customer' => definition })

    delete "#{base_url}/#{server.id}", params: { assistant_id: assistant.id }, headers: admin.create_new_auth_token, as: :json

    expect(response).to have_http_status(:no_content)
    expect(Captain::McpServer.exists?(server.id)).to be(false)
    expect(Captain::McpTool.where(mcp_server_id: server.id)).to be_empty
  end
end
