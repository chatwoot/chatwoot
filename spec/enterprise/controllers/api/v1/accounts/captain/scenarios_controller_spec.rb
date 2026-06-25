require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::Captain::Scenarios', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:assistant) { create(:captain_assistant, account: account) }

  def json_response
    JSON.parse(response.body, symbolize_names: true)
  end

  describe 'GET /api/v1/accounts/{account.id}/captain/assistants/{assistant.id}/scenarios' do
    context 'when it is an un-authenticated user' do
      it 'returns unauthorized status' do
        get "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/scenarios"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent' do
      it 'returns success status' do
        create_list(:captain_scenario, 3, assistant: assistant, account: account)
        get "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/scenarios",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(json_response[:payload].length).to eq(3)
      end
    end

    context 'when it is an admin' do
      it 'returns success status and scenarios' do
        create_list(:captain_scenario, 5, assistant: assistant, account: account)
        get "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/scenarios",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(json_response[:payload].length).to eq(5)
      end

      it 'returns only enabled scenarios' do
        create(:captain_scenario, assistant: assistant, account: account, enabled: true)
        create(:captain_scenario, assistant: assistant, account: account, enabled: false)
        get "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/scenarios",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(json_response[:payload].length).to eq(1)
        expect(json_response[:payload].first[:enabled]).to be(true)
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/captain/assistants/{assistant.id}/scenarios/{id}' do
    let(:scenario) { create(:captain_scenario, assistant: assistant, account: account) }

    context 'when it is an un-authenticated user' do
      it 'returns unauthorized status' do
        get "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/scenarios/#{scenario.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent' do
      it 'returns success status and scenario' do
        get "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/scenarios/#{scenario.id}",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(json_response[:id]).to eq(scenario.id)
        expect(json_response[:title]).to eq(scenario.title)
      end
    end

    context 'when scenario does not exist' do
      it 'returns not found status' do
        get "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/scenarios/999999",
            headers: agent.create_new_auth_token

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/captain/assistants/{assistant.id}/scenarios' do
    let(:valid_attributes) do
      {
        scenario: {
          title: 'Test Scenario',
          description: 'Test description',
          instruction: 'Test instruction',
          enabled: true,
          tools: %w[tool1 tool2]
        }
      }
    end

    context 'when it is an un-authenticated user' do
      it 'returns unauthorized status' do
        post "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/scenarios",
             params: valid_attributes
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent' do
      it 'returns unauthorized status' do
        post "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/scenarios",
             params: valid_attributes,
             headers: agent.create_new_auth_token
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an admin' do
      it 'creates a new scenario and returns success status' do
        expect do
          post "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/scenarios",
               params: valid_attributes,
               headers: admin.create_new_auth_token,
               as: :json
        end.to change(Captain::Scenario, :count).by(1)

        expect(response).to have_http_status(:success)
        expect(json_response[:title]).to eq('Test Scenario')
        expect(json_response[:description]).to eq('Test description')
        expect(json_response[:enabled]).to be(true)
        expect(json_response[:assistant_id]).to eq(assistant.id)
      end

      context 'with invalid parameters' do
        let(:invalid_attributes) do
          {
            scenario: {
              title: '',
              description: '',
              instruction: ''
            }
          }
        end

        it 'returns unprocessable entity status' do
          post "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/scenarios",
               params: invalid_attributes,
               headers: admin.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/captain/assistants/{assistant.id}/scenarios/{id}' do
    let(:scenario) { create(:captain_scenario, assistant: assistant, account: account) }
    let(:update_attributes) do
      {
        scenario: {
          title: 'Updated Scenario Title',
          enabled: false
        }
      }
    end

    context 'when it is an un-authenticated user' do
      it 'returns unauthorized status' do
        patch "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/scenarios/#{scenario.id}",
              params: update_attributes
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent' do
      it 'returns unauthorized status' do
        patch "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/scenarios/#{scenario.id}",
              params: update_attributes,
              headers: agent.create_new_auth_token
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an admin' do
      it 'updates the scenario and returns success status' do
        patch "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/scenarios/#{scenario.id}",
              params: update_attributes,
              headers: admin.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:success)
        expect(json_response[:title]).to eq('Updated Scenario Title')
        expect(json_response[:enabled]).to be(false)
      end

      context 'with invalid parameters' do
        let(:invalid_attributes) do
          {
            scenario: {
              title: ''
            }
          }
        end

        it 'returns unprocessable entity status' do
          patch "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/scenarios/#{scenario.id}",
                params: invalid_attributes,
                headers: admin.create_new_auth_token,
                as: :json

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/captain/assistants/{assistant.id}/scenarios/{id}' do
    let!(:scenario) { create(:captain_scenario, assistant: assistant, account: account) }

    context 'when it is an un-authenticated user' do
      it 'returns unauthorized status' do
        delete "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/scenarios/#{scenario.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent' do
      it 'returns unauthorized status' do
        delete "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/scenarios/#{scenario.id}",
               headers: agent.create_new_auth_token
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an admin' do
      it 'deletes the scenario and returns no content status' do
        expect do
          delete "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/scenarios/#{scenario.id}",
                 headers: admin.create_new_auth_token
        end.to change(Captain::Scenario, :count).by(-1)

        expect(response).to have_http_status(:no_content)
      end

      context 'when scenario does not exist' do
        it 'returns not found status' do
          delete "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/scenarios/999999",
                 headers: admin.create_new_auth_token

          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end
end
