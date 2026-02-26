require 'rails_helper'
require 'captain/mcp/errors'

RSpec.describe 'Api::V1::Accounts::Captain::McpServers', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }

  def json_response
    JSON.parse(response.body, symbolize_names: true)
  end

  before do
    account.enable_features('captain_mcp')
  end

  describe 'GET /api/v1/accounts/{account.id}/captain/mcp_servers' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized status' do
        get "/api/v1/accounts/#{account.id}/captain/mcp_servers"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent' do
      it 'returns unauthorized status' do
        get "/api/v1/accounts/#{account.id}/captain/mcp_servers",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an admin' do
      it 'returns success status and MCP servers' do
        create_list(:captain_mcp_server, 3, account: account)
        get "/api/v1/accounts/#{account.id}/captain/mcp_servers",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(json_response[:payload].length).to eq(3)
      end

      it 'returns servers ordered by created_at desc' do
        old_server = create(:captain_mcp_server, account: account, created_at: 2.days.ago)
        new_server = create(:captain_mcp_server, account: account, created_at: 1.day.ago)

        get "/api/v1/accounts/#{account.id}/captain/mcp_servers",
            headers: admin.create_new_auth_token,
            as: :json

        expect(json_response[:payload].first[:id]).to eq(new_server.id)
        expect(json_response[:payload].last[:id]).to eq(old_server.id)
      end
    end

    context 'when captain_mcp feature is disabled' do
      before { account.disable_features('captain_mcp') }

      it 'returns forbidden status' do
        get "/api/v1/accounts/#{account.id}/captain/mcp_servers",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/captain/mcp_servers/{id}' do
    let(:mcp_server) { create(:captain_mcp_server, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized status' do
        get "/api/v1/accounts/#{account.id}/captain/mcp_servers/#{mcp_server.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent' do
      it 'returns unauthorized status' do
        get "/api/v1/accounts/#{account.id}/captain/mcp_servers/#{mcp_server.id}",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an admin' do
      it 'returns success status and MCP server' do
        get "/api/v1/accounts/#{account.id}/captain/mcp_servers/#{mcp_server.id}",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(json_response[:id]).to eq(mcp_server.id)
        expect(json_response[:name]).to eq(mcp_server.name)
        expect(json_response[:url]).to eq(mcp_server.url)
      end

      it 'masks credentials in response' do
        server = create(:captain_mcp_server, :with_bearer_auth, account: account)

        get "/api/v1/accounts/#{account.id}/captain/mcp_servers/#{server.id}",
            headers: admin.create_new_auth_token,
            as: :json

        expect(json_response[:auth_config][:has_token]).to be true
        expect(json_response[:auth_config]).not_to have_key(:token)
      end
    end

    context 'when MCP server does not exist' do
      it 'returns not found status' do
        get "/api/v1/accounts/#{account.id}/captain/mcp_servers/999999",
            headers: admin.create_new_auth_token

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/captain/mcp_servers' do
    let(:valid_attributes) do
      {
        mcp_server: {
          name: 'Cloudflare Docs',
          description: 'Cloudflare documentation MCP server',
          url: 'https://mcp.cloudflare.com/api',
          auth_type: 'bearer',
          auth_config: { token: 'cf_token_xxx' },
          enabled: true
        }
      }
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized status' do
        post "/api/v1/accounts/#{account.id}/captain/mcp_servers",
             params: valid_attributes
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent' do
      it 'returns unauthorized status' do
        post "/api/v1/accounts/#{account.id}/captain/mcp_servers",
             params: valid_attributes,
             headers: agent.create_new_auth_token
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an admin' do
      it 'creates a new MCP server and returns success status' do
        post "/api/v1/accounts/#{account.id}/captain/mcp_servers",
             params: valid_attributes,
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(json_response[:name]).to eq('Cloudflare Docs')
        expect(json_response[:slug]).to eq('mcp_cloudflare_docs')
        expect(json_response[:url]).to eq('https://mcp.cloudflare.com/api')
        expect(json_response[:auth_type]).to eq('bearer')
      end

      context 'with invalid parameters' do
        let(:invalid_attributes) do
          {
            mcp_server: {
              name: '',
              url: ''
            }
          }
        end

        it 'returns unprocessable entity status' do
          post "/api/v1/accounts/#{account.id}/captain/mcp_servers",
               params: invalid_attributes,
               headers: admin.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context 'with localhost URL' do
        let(:localhost_attributes) do
          {
            mcp_server: {
              name: 'Local Server',
              url: 'http://localhost/api'
            }
          }
        end

        it 'returns unprocessable entity status' do
          post "/api/v1/accounts/#{account.id}/captain/mcp_servers",
               params: localhost_attributes,
               headers: admin.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/captain/mcp_servers/{id}' do
    let(:mcp_server) { create(:captain_mcp_server, account: account) }
    let(:update_attributes) do
      {
        mcp_server: {
          name: 'Updated Server Name',
          enabled: false
        }
      }
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized status' do
        patch "/api/v1/accounts/#{account.id}/captain/mcp_servers/#{mcp_server.id}",
              params: update_attributes
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent' do
      it 'returns unauthorized status' do
        patch "/api/v1/accounts/#{account.id}/captain/mcp_servers/#{mcp_server.id}",
              params: update_attributes,
              headers: agent.create_new_auth_token
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an admin' do
      it 'updates the MCP server and returns success status' do
        patch "/api/v1/accounts/#{account.id}/captain/mcp_servers/#{mcp_server.id}",
              params: update_attributes,
              headers: admin.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:success)
        expect(json_response[:name]).to eq('Updated Server Name')
        expect(json_response[:enabled]).to be(false)
      end

      it 'preserves existing credentials when not provided in update' do
        server = create(:captain_mcp_server, :with_bearer_auth, account: account)

        patch "/api/v1/accounts/#{account.id}/captain/mcp_servers/#{server.id}",
              params: { mcp_server: { name: 'New Name', auth_config: {} } },
              headers: admin.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:success)
        expect(server.reload.auth_config['token']).to eq('test_bearer_token_123')
      end

      context 'with invalid parameters' do
        let(:invalid_attributes) do
          {
            mcp_server: {
              name: ''
            }
          }
        end

        it 'returns unprocessable entity status' do
          patch "/api/v1/accounts/#{account.id}/captain/mcp_servers/#{mcp_server.id}",
                params: invalid_attributes,
                headers: admin.create_new_auth_token,
                as: :json

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/captain/mcp_servers/{id}' do
    let!(:mcp_server) { create(:captain_mcp_server, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized status' do
        delete "/api/v1/accounts/#{account.id}/captain/mcp_servers/#{mcp_server.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent' do
      it 'returns unauthorized status' do
        delete "/api/v1/accounts/#{account.id}/captain/mcp_servers/#{mcp_server.id}",
               headers: agent.create_new_auth_token
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an admin' do
      it 'deletes the MCP server and returns no content status' do
        expect do
          delete "/api/v1/accounts/#{account.id}/captain/mcp_servers/#{mcp_server.id}",
                 headers: admin.create_new_auth_token
        end.to change(Captain::McpServer, :count).by(-1)

        expect(response).to have_http_status(:no_content)
      end

      it 'also deletes associated assistant attachments' do
        assistant = create(:captain_assistant, account: account)
        create(:captain_assistant_mcp_server, assistant: assistant, mcp_server: mcp_server)

        expect do
          delete "/api/v1/accounts/#{account.id}/captain/mcp_servers/#{mcp_server.id}",
                 headers: admin.create_new_auth_token
        end.to change(Captain::AssistantMcpServer, :count).by(-1)
      end

      context 'when MCP server does not exist' do
        it 'returns not found status' do
          delete "/api/v1/accounts/#{account.id}/captain/mcp_servers/999999",
                 headers: admin.create_new_auth_token

          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/captain/mcp_servers/{id}/connect' do
    let(:mcp_server) { create(:captain_mcp_server, account: account) }

    context 'when it is an admin' do
      let(:mock_discovery_service) { instance_double(Captain::Mcp::DiscoveryService) }

      before do
        allow(Captain::Mcp::DiscoveryService).to receive(:new).and_return(mock_discovery_service)
      end

      it 'connects and returns tools count' do
        allow(mock_discovery_service).to receive(:connect_and_discover)
        mcp_server.update!(cached_tools: [{ 'name' => 'tool1' }, { 'name' => 'tool2' }])

        post "/api/v1/accounts/#{account.id}/captain/mcp_servers/#{mcp_server.id}/connect",
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(json_response[:status]).to eq('connected')
        expect(json_response[:tools_count]).to eq(2)
      end

      it 'returns error when connection fails' do
        allow(mock_discovery_service).to receive(:connect_and_discover)
          .and_raise(Captain::Mcp::ConnectionError.new('Connection refused'))

        post "/api/v1/accounts/#{account.id}/captain/mcp_servers/#{mcp_server.id}/connect",
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response[:error]).to include('Connection refused')
      end
    end

    context 'when it is an agent' do
      it 'returns unauthorized status' do
        post "/api/v1/accounts/#{account.id}/captain/mcp_servers/#{mcp_server.id}/connect",
             headers: agent.create_new_auth_token

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/captain/mcp_servers/{id}/disconnect' do
    let(:mcp_server) { create(:captain_mcp_server, :connected, account: account) }

    context 'when it is an admin' do
      let(:mock_client_service) { instance_double(Captain::Mcp::ClientService) }

      before do
        allow(Captain::Mcp::ClientService).to receive(:new).and_return(mock_client_service)
        allow(mock_client_service).to receive(:disconnect)
      end

      it 'disconnects and returns status' do
        post "/api/v1/accounts/#{account.id}/captain/mcp_servers/#{mcp_server.id}/disconnect",
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(json_response[:status]).to eq('disconnected')
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/captain/mcp_servers/{id}/refresh' do
    let(:mcp_server) { create(:captain_mcp_server, :connected, account: account) }

    context 'when it is an admin' do
      let(:mock_discovery_service) { instance_double(Captain::Mcp::DiscoveryService) }
      let(:new_tools) { [{ 'name' => 'new_tool', 'description' => 'A new tool' }] }

      before do
        allow(Captain::Mcp::DiscoveryService).to receive(:new).and_return(mock_discovery_service)
      end

      it 'refreshes tools and returns updated server' do
        allow(mock_discovery_service).to receive(:refresh_tools).and_return(new_tools)
        mcp_server.update!(cached_tools: new_tools)

        post "/api/v1/accounts/#{account.id}/captain/mcp_servers/#{mcp_server.id}/refresh",
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(json_response[:cached_tools]).to eq([{ name: 'new_tool', description: 'A new tool' }])
      end

      it 'returns error when refresh fails' do
        allow(mock_discovery_service).to receive(:refresh_tools)
          .and_raise(Captain::Mcp::Error.new('Failed to refresh'))

        post "/api/v1/accounts/#{account.id}/captain/mcp_servers/#{mcp_server.id}/refresh",
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response[:error]).to include('Failed to refresh')
      end
    end
  end
end
