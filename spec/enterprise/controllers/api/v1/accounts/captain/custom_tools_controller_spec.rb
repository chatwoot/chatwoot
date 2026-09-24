require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::Captain::CustomTools', type: :request do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }

  before { account.enable_features!('custom_tools') }

  def json_response
    JSON.parse(response.body, symbolize_names: true)
  end

  describe 'GET /api/v1/accounts/{account.id}/captain/custom_tools' do
    context 'when it is an un-authenticated user' do
      it 'returns unauthorized status' do
        get "/api/v1/accounts/#{account.id}/captain/custom_tools?assistant_id=#{assistant.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent' do
      it 'returns success status' do
        create_list(:captain_custom_tool, 3, account: account, assistant: assistant)
        get "/api/v1/accounts/#{account.id}/captain/custom_tools?assistant_id=#{assistant.id}",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(json_response[:payload].length).to eq(3)
      end
    end

    context 'when it is an admin' do
      it 'returns success status and custom tools' do
        create_list(:captain_custom_tool, 5, account: account, assistant: assistant)
        get "/api/v1/accounts/#{account.id}/captain/custom_tools?assistant_id=#{assistant.id}",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(json_response[:payload].length).to eq(5)
      end

      it 'returns all custom tools including disabled' do
        create(:captain_custom_tool, account: account, assistant: assistant, enabled: true)
        create(:captain_custom_tool, account: account, assistant: assistant, enabled: false)
        get "/api/v1/accounts/#{account.id}/captain/custom_tools?assistant_id=#{assistant.id}",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(json_response[:payload].length).to eq(2)
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/captain/custom_tools/{id}' do
    let(:custom_tool) { create(:captain_custom_tool, account: account, assistant: assistant) }

    context 'when it is an un-authenticated user' do
      it 'returns unauthorized status' do
        get "/api/v1/accounts/#{account.id}/captain/custom_tools/#{custom_tool.id}?assistant_id=#{assistant.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent' do
      it 'returns success status and custom tool' do
        get "/api/v1/accounts/#{account.id}/captain/custom_tools/#{custom_tool.id}?assistant_id=#{assistant.id}",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(json_response[:id]).to eq(custom_tool.id)
        expect(json_response[:title]).to eq(custom_tool.title)
      end
    end

    context 'when custom tool does not exist' do
      it 'returns not found status' do
        get "/api/v1/accounts/#{account.id}/captain/custom_tools/999999?assistant_id=#{assistant.id}",
            headers: agent.create_new_auth_token

        expect(response).to have_http_status(:not_found)
      end
    end

    it 'returns the number of enabled scenarios referencing the tool' do
      custom_tool.update!(slug: 'custom_fetch-order')
      instruction = 'Use [@Fetch Order](tool://custom_fetch-order) to get order details'
      create(:captain_scenario, assistant: assistant, account: account, instruction: instruction, enabled: true)
      create(:captain_scenario, assistant: assistant, account: account, instruction: instruction, enabled: false)

      get "/api/v1/accounts/#{account.id}/captain/custom_tools/#{custom_tool.id}?assistant_id=#{assistant.id}",
          headers: admin.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:success)
      expect(json_response[:enabled_scenarios_count]).to eq(1)
    end

    it 'returns headers only to administrators' do
      custom_tool.update!(headers: { 'X-Tenant-Id' => 'acme' })

      get "/api/v1/accounts/#{account.id}/captain/custom_tools/#{custom_tool.id}?assistant_id=#{assistant.id}",
          headers: admin.create_new_auth_token,
          as: :json
      expect(json_response[:headers]).to eq({ 'X-Tenant-Id': 'acme' })

      get "/api/v1/accounts/#{account.id}/captain/custom_tools/#{custom_tool.id}?assistant_id=#{assistant.id}",
          headers: agent.create_new_auth_token,
          as: :json
      expect(json_response).not_to have_key(:headers)
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/captain/custom_tools' do
    let(:valid_attributes) do
      {
        custom_tool: {
          title: 'Fetch Order Status',
          description: 'Fetches order status from external API',
          endpoint_url: 'https://api.example.com/orders/{{ order_id }}',
          http_method: 'GET',
          enabled: true,
          param_schema: [
            { name: 'order_id', type: 'string', description: 'The order ID', required: true }
          ]
        }
      }
    end

    context 'when it is an un-authenticated user' do
      it 'returns unauthorized status' do
        post "/api/v1/accounts/#{account.id}/captain/custom_tools?assistant_id=#{assistant.id}",
             params: valid_attributes
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent' do
      it 'returns unauthorized status' do
        post "/api/v1/accounts/#{account.id}/captain/custom_tools?assistant_id=#{assistant.id}",
             params: valid_attributes,
             headers: agent.create_new_auth_token
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an admin' do
      it 'creates a new custom tool and returns success status' do
        post "/api/v1/accounts/#{account.id}/captain/custom_tools?assistant_id=#{assistant.id}",
             params: valid_attributes,
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(json_response[:title]).to eq('Fetch Order Status')
        expect(json_response[:description]).to eq('Fetches order status from external API')
        expect(json_response[:enabled]).to be(true)
        expect(json_response[:slug]).to eq('custom_fetch_order_status')
        expect(json_response[:param_schema]).to eq([
                                                     { name: 'order_id', type: 'string', description: 'The order ID', required: true }
                                                   ])
      end

      context 'with invalid parameters' do
        let(:invalid_attributes) do
          {
            custom_tool: {
              title: '',
              endpoint_url: ''
            }
          }
        end

        it 'returns unprocessable entity status' do
          post "/api/v1/accounts/#{account.id}/captain/custom_tools?assistant_id=#{assistant.id}",
               params: invalid_attributes,
               headers: admin.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context 'with invalid endpoint URL' do
        let(:invalid_url_attributes) do
          {
            custom_tool: {
              title: 'Test Tool',
              endpoint_url: 'http://localhost/api',
              http_method: 'GET'
            }
          }
        end

        it 'returns unprocessable entity status' do
          post "/api/v1/accounts/#{account.id}/captain/custom_tools?assistant_id=#{assistant.id}",
               params: invalid_url_attributes,
               headers: admin.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      it 'creates a custom tool with static headers' do
        post "/api/v1/accounts/#{account.id}/captain/custom_tools?assistant_id=#{assistant.id}",
             params: valid_attributes.deep_merge(custom_tool: { headers: { 'X-Tenant-Id' => 'acme' } }),
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(Captain::CustomTool.find(json_response[:id]).headers).to eq('X-Tenant-Id' => 'acme')
      end

      it 'accepts an empty headers object' do
        post "/api/v1/accounts/#{account.id}/captain/custom_tools?assistant_id=#{assistant.id}",
             params: valid_attributes.deep_merge(custom_tool: { headers: {} }),
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
      end

      it 'rejects headers that are not an object' do
        [['X-Tenant-Id'], 'X-Tenant-Id: acme', nil].each do |headers|
          post "/api/v1/accounts/#{account.id}/captain/custom_tools?assistant_id=#{assistant.id}",
               params: valid_attributes.deep_merge(custom_tool: { headers: headers }),
               headers: admin.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:unprocessable_entity), "expected #{headers.inspect} to be rejected"
          expect(json_response[:error]).to eq('Headers must be an object of header names and values')
        end
        expect(assistant.custom_tools.count).to eq(0)
      end

      it 'rejects invalid headers' do
        post "/api/v1/accounts/#{account.id}/captain/custom_tools?assistant_id=#{assistant.id}",
             params: valid_attributes.deep_merge(custom_tool: { headers: { 'Host' => 'internal.example.com' } }),
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/captain/custom_tools/test' do
    before { allow(Resolv).to receive(:getaddresses).and_return(['93.184.216.34']) }

    it 'sends the custom headers with the test request' do
      stub_request(:get, 'https://api.example.com/health')
        .with(headers: { 'cal-api-version' => '2024-08-13' })
        .to_return(status: 200, body: 'ok')

      post "/api/v1/accounts/#{account.id}/captain/custom_tools/test?assistant_id=#{assistant.id}",
           params: { custom_tool: { endpoint_url: 'https://api.example.com/health', http_method: 'GET',
                                    headers: { 'cal-api-version' => '2024-08-13' } } },
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:success)
      expect(WebMock).to have_requested(:get, 'https://api.example.com/health')
        .with(headers: { 'cal-api-version' => '2024-08-13' })
    end

    it 'rejects reserved headers without sending the request' do
      post "/api/v1/accounts/#{account.id}/captain/custom_tools/test?assistant_id=#{assistant.id}",
           params: { custom_tool: { endpoint_url: 'https://api.example.com/health', http_method: 'GET',
                                    headers: { 'Host' => 'internal.example.com' } } },
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response[:error]).to include('Host')
      expect(WebMock).not_to have_requested(:any, /.*/)
    end

    it 'rejects invalid auth config without sending the request' do
      post "/api/v1/accounts/#{account.id}/captain/custom_tools/test?assistant_id=#{assistant.id}",
           params: { custom_tool: { endpoint_url: 'https://api.example.com/health', http_method: 'GET',
                                    auth_type: 'api_key', auth_config: { name: 'Content-Type', key: 'secret' } } },
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response[:error]).to include('Content-Type')
      expect(WebMock).not_to have_requested(:any, /.*/)
    end

    it 'rejects unsafe endpoint URLs without sending the request' do
      post "/api/v1/accounts/#{account.id}/captain/custom_tools/test?assistant_id=#{assistant.id}",
           params: { custom_tool: { endpoint_url: 'http://api.example.com/health', http_method: 'GET' } },
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response[:error]).to include('HTTPS')
      expect(WebMock).not_to have_requested(:any, /.*/)
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/captain/custom_tools/{id}' do
    let(:custom_tool) { create(:captain_custom_tool, account: account, assistant: assistant) }
    let(:update_attributes) do
      {
        custom_tool: {
          title: 'Updated Tool Title',
          enabled: false
        }
      }
    end

    context 'when it is an un-authenticated user' do
      it 'returns unauthorized status' do
        patch "/api/v1/accounts/#{account.id}/captain/custom_tools/#{custom_tool.id}?assistant_id=#{assistant.id}",
              params: update_attributes
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent' do
      it 'returns unauthorized status' do
        patch "/api/v1/accounts/#{account.id}/captain/custom_tools/#{custom_tool.id}?assistant_id=#{assistant.id}",
              params: update_attributes,
              headers: agent.create_new_auth_token
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an admin' do
      it 'updates the custom tool and returns success status' do
        patch "/api/v1/accounts/#{account.id}/captain/custom_tools/#{custom_tool.id}?assistant_id=#{assistant.id}",
              params: update_attributes,
              headers: admin.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:success)
        expect(json_response[:title]).to eq('Updated Tool Title')
        expect(json_response[:enabled]).to be(false)
        expect(custom_tool.reload.enabled).to be(false)
      end

      context 'with invalid parameters' do
        let(:invalid_attributes) do
          {
            custom_tool: {
              title: ''
            }
          }
        end

        it 'returns unprocessable entity status' do
          patch "/api/v1/accounts/#{account.id}/captain/custom_tools/#{custom_tool.id}?assistant_id=#{assistant.id}",
                params: invalid_attributes,
                headers: admin.create_new_auth_token,
                as: :json

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/captain/custom_tools/{id}' do
    let!(:custom_tool) { create(:captain_custom_tool, account: account, assistant: assistant) }

    context 'when it is an un-authenticated user' do
      it 'returns unauthorized status' do
        delete "/api/v1/accounts/#{account.id}/captain/custom_tools/#{custom_tool.id}?assistant_id=#{assistant.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent' do
      it 'returns unauthorized status' do
        delete "/api/v1/accounts/#{account.id}/captain/custom_tools/#{custom_tool.id}?assistant_id=#{assistant.id}",
               headers: agent.create_new_auth_token
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an admin' do
      it 'deletes the custom tool and returns no content status' do
        expect do
          delete "/api/v1/accounts/#{account.id}/captain/custom_tools/#{custom_tool.id}?assistant_id=#{assistant.id}",
                 headers: admin.create_new_auth_token
        end.to change(Captain::CustomTool, :count).by(-1)

        expect(response).to have_http_status(:no_content)
      end

      context 'when custom tool does not exist' do
        it 'returns not found status' do
          delete "/api/v1/accounts/#{account.id}/captain/custom_tools/999999?assistant_id=#{assistant.id}",
                 headers: admin.create_new_auth_token

          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end
end
