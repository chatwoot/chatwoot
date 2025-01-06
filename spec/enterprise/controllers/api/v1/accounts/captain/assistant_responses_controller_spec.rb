require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::Captain::AssistantResponses', type: :request do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:document) { create(:captain_document, account: account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }

  describe 'GET /api/v1/accounts/:account_id/captain/assistants/:assistant_id/assistant_responses' do
    it 'returns a successful response' do
      create_list(:captain_assistant_response, 3, assistant: assistant, account: account)
      get "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/assistant_responses",
          headers: agent.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response.length).to eq(3)
    end

    context 'with different account' do
      let(:other_account) { create(:account) }
      let(:other_assistant) { create(:captain_assistant, account: other_account) }

      it 'returns no responses' do
        get "/api/v1/accounts/#{account.id}/captain/assistants/#{other_assistant.id}/assistant_responses",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'GET /api/v1/accounts/:account_id/captain/assistants/:assistant_id/assistant_responses/:id' do
    let!(:response_record) { create(:captain_assistant_response, assistant: assistant, account: account) }

    it 'returns the requested response if the user is agent or admin' do
      get "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/assistant_responses/#{response_record.id}",
          headers: agent.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['id']).to eq(response_record.id)
      expect(json_response['question']).to eq(response_record.question)
      expect(json_response['answer']).to eq(response_record.answer)
    end
  end

  describe 'POST /api/v1/accounts/:account_id/captain/assistants/:assistant_id/assistant_responses' do
    let(:valid_params) do
      {
        assistant_response: {
          question: 'Test question?',
          answer: 'Test answer'
        }
      }
    end

    it 'creates a new response if the user is an admin' do
      expect do
        post "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/assistant_responses",
             params: valid_params,
             headers: admin.create_new_auth_token,
             as: :json
      end.to change(Captain::AssistantResponse, :count).by(1)

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)

      expect(json_response['question']).to eq('Test question?')
      expect(json_response['answer']).to eq('Test answer')
    end

    context 'with invalid params' do
      let(:invalid_params) do
        {
          assistant_response: {
            question: '',
            answer: ''
          }
        }
      end

      it 'returns unprocessable entity status' do
        post "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/assistant_responses",
             params: invalid_params,
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PATCH /api/v1/accounts/:account_id/captain/assistants/:assistant_id/assistant_responses/:id' do
    let!(:response_record) { create(:captain_assistant_response, assistant: assistant) }
    let(:update_params) do
      {
        assistant_response: {
          question: 'Updated question?',
          answer: 'Updated answer'
        }
      }
    end

    it 'updates the response if the user is an admin' do
      patch "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/assistant_responses/#{response_record.id}",
            params: update_params,
            headers: admin.create_new_auth_token,
            as: :json

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)

      expect(json_response['question']).to eq('Updated question?')
      expect(json_response['answer']).to eq('Updated answer')
    end

    context 'with invalid params' do
      let(:invalid_params) do
        {
          assistant_response: {
            question: '',
            answer: ''
          }
        }
      end

      it 'returns unprocessable entity status' do
        patch "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/assistant_responses/#{response_record.id}",
              params: invalid_params,
              headers: admin.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'DELETE /api/v1/accounts/:account_id/captain/assistants/:assistant_id/assistant_responses/:id' do
    let!(:response_record) { create(:captain_assistant_response, assistant: assistant) }

    it 'deletes the response' do
      expect do
        delete "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/assistant_responses/#{response_record.id}",
               headers: admin.create_new_auth_token,
               as: :json
      end.to change(Captain::AssistantResponse, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    context 'with invalid id' do
      it 'returns not found' do
        delete "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/assistant_responses/0",
               headers: admin.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
