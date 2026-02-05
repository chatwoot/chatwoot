require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::Captain::Assistants::McpServers', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:mcp_server) { create(:captain_mcp_server, :connected, account: account) }

  def json_response
    JSON.parse(response.body, symbolize_names: true)
  end

  before do
    account.enable_features('captain_mcp')
  end

  describe 'GET /api/v1/accounts/{account.id}/captain/assistants/{assistant.id}/mcp_servers' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized status' do
        get "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/mcp_servers"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent' do
      it 'returns success status (agents can view assistants)' do
        get "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/mcp_servers",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
      end
    end

    context 'when it is an admin' do
      it 'returns success status and attached MCP servers' do
        create_list(:captain_assistant_mcp_server, 2, assistant: assistant)

        get "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/mcp_servers",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(json_response[:payload].length).to eq(2)
      end

      it 'includes mcp_server details in response' do
        attachment = create(:captain_assistant_mcp_server, assistant: assistant, mcp_server: mcp_server)

        get "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/mcp_servers",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(json_response[:payload].first[:id]).to eq(attachment.id)
        expect(json_response[:payload].first[:mcp_server][:id]).to eq(mcp_server.id)
      end

      it 'returns empty payload when no servers attached' do
        get "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/mcp_servers",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(json_response[:payload]).to eq([])
      end
    end

    context 'when captain_mcp feature is disabled' do
      before { account.disable_features('captain_mcp') }

      it 'returns forbidden status' do
        get "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/mcp_servers",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/captain/assistants/{assistant.id}/mcp_servers' do
    let(:valid_attributes) do
      {
        assistant_mcp_server: {
          captain_mcp_server_id: mcp_server.id,
          enabled: true,
          tool_filters: { include: ['search_docs'] }
        }
      }
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized status' do
        post "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/mcp_servers",
             params: valid_attributes
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent' do
      it 'returns unauthorized status' do
        post "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/mcp_servers",
             params: valid_attributes,
             headers: agent.create_new_auth_token
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an admin' do
      it 'attaches MCP server to assistant and returns success status' do
        post "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/mcp_servers",
             params: valid_attributes,
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(json_response[:captain_mcp_server_id]).to eq(mcp_server.id)
        expect(json_response[:enabled]).to be(true)
        expect(json_response[:tool_filters][:include]).to eq(['search_docs'])
      end

      it 'creates association in database' do
        expect do
          post "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/mcp_servers",
               params: valid_attributes,
               headers: admin.create_new_auth_token,
               as: :json
        end.to change(Captain::AssistantMcpServer, :count).by(1)
      end

      context 'when server is already attached' do
        before do
          create(:captain_assistant_mcp_server, assistant: assistant, mcp_server: mcp_server)
        end

        it 'returns unprocessable entity status' do
          post "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/mcp_servers",
               params: valid_attributes,
               headers: admin.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context 'with invalid MCP server ID' do
        let(:invalid_attributes) do
          {
            assistant_mcp_server: {
              captain_mcp_server_id: 999_999
            }
          }
        end

        it 'returns not found status' do
          post "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/mcp_servers",
               params: invalid_attributes,
               headers: admin.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/captain/assistants/{assistant.id}/mcp_servers/{id}' do
    let!(:attachment) { create(:captain_assistant_mcp_server, assistant: assistant, mcp_server: mcp_server) }
    let(:update_attributes) do
      {
        assistant_mcp_server: {
          enabled: false,
          tool_filters: { exclude: ['get_page'] }
        }
      }
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized status' do
        patch "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/mcp_servers/#{attachment.id}",
              params: update_attributes
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent' do
      it 'returns unauthorized status' do
        patch "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/mcp_servers/#{attachment.id}",
              params: update_attributes,
              headers: agent.create_new_auth_token
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an admin' do
      it 'updates the attachment and returns success status' do
        patch "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/mcp_servers/#{attachment.id}",
              params: update_attributes,
              headers: admin.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:success)
        expect(json_response[:enabled]).to be(false)
        expect(json_response[:tool_filters][:exclude]).to eq(['get_page'])
      end

      it 'updates tool_filters in database' do
        patch "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/mcp_servers/#{attachment.id}",
              params: update_attributes,
              headers: admin.create_new_auth_token,
              as: :json

        expect(attachment.reload.tool_filters['exclude']).to eq(['get_page'])
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/captain/assistants/{assistant.id}/mcp_servers/{id}' do
    let!(:attachment) { create(:captain_assistant_mcp_server, assistant: assistant, mcp_server: mcp_server) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized status' do
        delete "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/mcp_servers/#{attachment.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent' do
      it 'returns unauthorized status' do
        delete "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/mcp_servers/#{attachment.id}",
               headers: agent.create_new_auth_token
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an admin' do
      it 'detaches MCP server and returns no content status' do
        expect do
          delete "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/mcp_servers/#{attachment.id}",
                 headers: admin.create_new_auth_token
        end.to change(Captain::AssistantMcpServer, :count).by(-1)

        expect(response).to have_http_status(:no_content)
      end

      it 'does not delete the MCP server itself' do
        expect do
          delete "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/mcp_servers/#{attachment.id}",
                 headers: admin.create_new_auth_token
        end.not_to change(Captain::McpServer, :count)
      end

      context 'when attachment does not exist' do
        it 'returns not found status' do
          delete "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/mcp_servers/999999",
                 headers: admin.create_new_auth_token

          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end
end
