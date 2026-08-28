require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::Captain::AssistantResponses', type: :request do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:document) { create(:captain_document, assistant: assistant, account: account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:another_assistant) { create(:captain_assistant, account: account) }
  let(:another_document) { create(:captain_document, account: account, assistant: assistant) }

  def json_response
    JSON.parse(response.body, symbolize_names: true)
  end

  describe 'GET /api/v1/accounts/:account_id/captain/assistant_responses' do
    context 'when showing conversation usage' do
      let!(:manual_response) do
        create(:captain_assistant_response, account: account, assistant: assistant, documentable: admin)
      end
      let!(:approved_suggestion) do
        create(:captain_assistant_response, account: account, assistant: assistant, documentable: nil)
      end
      let!(:document_response) do
        create(:captain_assistant_response, account: account, assistant: assistant, documentable: document)
      end
      let!(:first_conversation) { create(:conversation, account: account) }
      let!(:second_conversation) { create(:conversation, account: account) }

      before do
        create(:captain_agent_session, account: account, assistant: assistant,
                                       subject: first_conversation, used_faq_ids: [manual_response.id], credits_consumed: 1.0)
        create(:captain_agent_session, account: account, assistant: assistant,
                                       subject: first_conversation, used_faq_ids: [manual_response.id], credits_consumed: 1.0)
        create(:captain_agent_session, account: account, assistant: assistant,
                                       subject: second_conversation, used_faq_ids: [manual_response.id], credits_consumed: 1.0)
        create(:captain_agent_session, account: account, assistant: another_assistant,
                                       subject: second_conversation, used_faq_ids: [manual_response.id], credits_consumed: 1.0)
      end

      it 'returns distinct conversation usage only for user-created FAQs to an admin' do
        get "/api/v1/accounts/#{account.id}/captain/assistant_responses",
            params: { assistant_id: assistant.id },
            headers: admin.create_new_auth_token,
            as: :json

        responses_by_id = json_response[:payload].index_by { |item| item[:id] }

        expect(responses_by_id.dig(manual_response.id, :used_in_conversations_count)).to eq(2)
        expect(responses_by_id[approved_suggestion.id]).not_to have_key(:used_in_conversations_count)
        expect(responses_by_id[document_response.id]).not_to have_key(:used_in_conversations_count)
      end

      it 'excludes handoff sessions from manual FAQ usage' do
        handoff_response = create(:captain_assistant_response, account: account, assistant: assistant, documentable: admin)
        handoff_conversation = create(:conversation, account: account)
        create(:captain_agent_session, account: account, assistant: assistant,
                                       subject: handoff_conversation, used_faq_ids: [handoff_response.id], credits_consumed: 0.0)

        get "/api/v1/accounts/#{account.id}/captain/assistant_responses",
            params: { assistant_id: assistant.id },
            headers: admin.create_new_auth_token,
            as: :json

        response_json = json_response[:payload].find { |item| item[:id] == handoff_response.id }
        expect(response_json[:used_in_conversations_count]).to eq(0)

        get "/api/v1/accounts/#{account.id}/captain/assistant_responses/#{handoff_response.id}/drilldown",
            headers: admin.create_new_auth_token,
            as: :json

        expect(json_response[:meta][:conversation_count]).to eq(0)
        expect(json_response[:payload]).to be_empty
      end

      it 'excludes deleted conversations from user-created FAQ usage counts' do
        deleted_conversation = create(:conversation, account: account)
        deleted_session = create(:captain_agent_session, account: account, assistant: assistant,
                                                         subject: deleted_conversation,
                                                         used_faq_ids: [manual_response.id], credits_consumed: 1.0)
        deleted_conversation.destroy!
        expect(deleted_session.reload).to be_present

        get "/api/v1/accounts/#{account.id}/captain/assistant_responses",
            params: { assistant_id: assistant.id },
            headers: admin.create_new_auth_token,
            as: :json

        response_json = json_response[:payload].find { |item| item[:id] == manual_response.id }
        expect(response_json[:used_in_conversations_count]).to eq(2)
      end

      it 'does not expose conversation usage to an agent' do
        get "/api/v1/accounts/#{account.id}/captain/assistant_responses",
            params: { assistant_id: assistant.id },
            headers: agent.create_new_auth_token,
            as: :json

        manual_response_json = json_response[:payload].find { |item| item[:id] == manual_response.id }
        expect(manual_response_json).not_to have_key(:used_in_conversations_count)
      end
    end

    context 'when no filters are applied' do
      before do
        create_list(:captain_assistant_response, 30,
                    account: account,
                    assistant: assistant,
                    documentable: document)
      end

      it 'returns first page of responses with default pagination' do
        get "/api/v1/accounts/#{account.id}/captain/assistant_responses",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response[:payload].length).to eq(25)
      end

      it 'returns second page of responses' do
        get "/api/v1/accounts/#{account.id}/captain/assistant_responses",
            params: { page: 2 },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response[:payload].length).to eq(5)
        expect(json_response[:meta]).to eq({ page: 2, total_count: 30 })
      end
    end

    context 'when filtering by assistant_id' do
      before do
        create_list(:captain_assistant_response, 3,
                    account: account,
                    assistant: assistant,
                    documentable: document)
        create_list(:captain_assistant_response, 2,
                    account: account,
                    assistant: another_assistant,
                    documentable: document)
      end

      it 'returns only responses for the specified assistant' do
        get "/api/v1/accounts/#{account.id}/captain/assistant_responses",
            params: { assistant_id: assistant.id },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response[:payload].length).to eq(3)
        expect(json_response[:payload][0][:assistant][:id]).to eq(assistant.id)
      end
    end

    context 'when filtering by document_id' do
      before do
        create_list(:captain_assistant_response, 3,
                    account: account,
                    assistant: assistant,
                    documentable: document)
        create_list(:captain_assistant_response, 2,
                    account: account,
                    assistant: assistant,
                    documentable: another_document)
      end

      it 'returns only responses for the specified document' do
        get "/api/v1/accounts/#{account.id}/captain/assistant_responses",
            params: { document_id: document.id },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response[:payload].length).to eq(3)
        expect(json_response[:payload][0][:documentable][:id]).to eq(document.id)
      end
    end

    context 'when searching' do
      before do
        create(:captain_assistant_response,
               account: account,
               assistant: assistant,
               question: 'How to reset password?',
               answer: 'Click forgot password')
        create(:captain_assistant_response,
               account: account,
               assistant: assistant,
               question: 'How to change email?',
               answer: 'Go to settings')
      end

      it 'finds responses by question text' do
        get "/api/v1/accounts/#{account.id}/captain/assistant_responses",
            params: { search: 'password' },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response[:payload].length).to eq(1)
        expect(json_response[:payload][0][:question]).to include('password')
      end

      it 'finds responses by answer text' do
        get "/api/v1/accounts/#{account.id}/captain/assistant_responses",
            params: { search: 'settings' },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response[:payload].length).to eq(1)
        expect(json_response[:payload][0][:answer]).to include('settings')
      end

      it 'returns empty when no matches' do
        get "/api/v1/accounts/#{account.id}/captain/assistant_responses",
            params: { search: 'nonexistent' },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response[:payload].length).to eq(0)
      end
    end
  end

  describe 'GET /api/v1/accounts/:account_id/captain/assistant_responses/:id' do
    let!(:response_record) { create(:captain_assistant_response, assistant: assistant, account: account) }

    it 'returns the requested response if the user is agent or admin' do
      get "/api/v1/accounts/#{account.id}/captain/assistant_responses/#{response_record.id}",
          headers: agent.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response[:id]).to eq(response_record.id)
      expect(json_response[:question]).to eq(response_record.question)
      expect(json_response[:answer]).to eq(response_record.answer)
    end
  end

  describe 'GET /api/v1/accounts/:account_id/captain/assistant_responses/:id/drilldown' do
    let!(:manual_response) do
      create(:captain_assistant_response, account: account, assistant: assistant, documentable: admin)
    end
    let!(:approved_suggestion) do
      create(:captain_assistant_response, account: account, assistant: assistant, documentable: nil)
    end
    let!(:older_conversation) do
      create(:conversation, account: account, last_activity_at: 2.days.ago)
    end
    let!(:newer_conversation) do
      create(:conversation, account: account, last_activity_at: 1.day.ago)
    end

    before do
      create(:captain_agent_session, account: account, assistant: assistant,
                                     subject: older_conversation, used_faq_ids: [manual_response.id], credits_consumed: 1.0)
      create(:captain_agent_session, account: account, assistant: assistant,
                                     subject: newer_conversation, used_faq_ids: [manual_response.id], credits_consumed: 1.0)
      create(:captain_agent_session, account: account, assistant: assistant,
                                     subject: newer_conversation, used_faq_ids: [manual_response.id], credits_consumed: 1.0)
    end

    it 'returns unauthorized for an agent' do
      get "/api/v1/accounts/#{account.id}/captain/assistant_responses/#{manual_response.id}/drilldown",
          headers: agent.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns distinct conversations through the shared drilldown contract for an admin' do
      get "/api/v1/accounts/#{account.id}/captain/assistant_responses/#{manual_response.id}/drilldown",
          params: { per_page: 1 },
          headers: admin.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response[:meta]).to include(
        current_page: 1,
        per_page: 1,
        total_count: 2,
        conversation_count: 2
      )
      expect(json_response[:payload].length).to eq(1)
      expect(json_response.dig(:payload, 0, :record_type)).to eq('conversation')
      expect(json_response.dig(:payload, 0, :conversation, :id)).to eq(newer_conversation.id)
    end

    it 'does not expose drilldown for an approved FAQ suggestion' do
      get "/api/v1/accounts/#{account.id}/captain/assistant_responses/#{approved_suggestion.id}/drilldown",
          headers: admin.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/v1/accounts/:account_id/captain/assistant_responses' do
    let(:valid_params) do
      {
        assistant_response: {
          question: 'Test question?',
          answer: 'Test answer',
          assistant_id: assistant.id
        }
      }
    end

    it 'creates a new response if the user is an admin' do
      expect do
        post "/api/v1/accounts/#{account.id}/captain/assistant_responses",
             params: valid_params,
             headers: admin.create_new_auth_token,
             as: :json
      end.to change(Captain::AssistantResponse, :count).by(1)

      expect(response).to have_http_status(:success)

      expect(json_response[:question]).to eq('Test question?')
      expect(json_response[:answer]).to eq('Test answer')
      expect(json_response[:status]).to eq('approved')
    end

    it 'does not accept the removed pending status' do
      params = valid_params.deep_merge(assistant_response: { status: 'pending' })

      post "/api/v1/accounts/#{account.id}/captain/assistant_responses",
           params: params,
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:success)
      expect(Captain::AssistantResponse.last).to be_approved
    end

    it 'does not create a response for an assistant in another account' do
      other_assistant = create(:captain_assistant)
      params = valid_params.deep_merge(assistant_response: { assistant_id: other_assistant.id })

      expect do
        post "/api/v1/accounts/#{account.id}/captain/assistant_responses",
             params: params,
             headers: admin.create_new_auth_token,
             as: :json
      end.not_to change(Captain::AssistantResponse, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    context 'with invalid params' do
      let(:invalid_params) do
        {
          assistant_response: {
            question: 'Test',
            answer: 'Test'
          }
        }
      end

      it 'returns unprocessable entity status' do
        post "/api/v1/accounts/#{account.id}/captain/assistant_responses",
             params: invalid_params,
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PATCH /api/v1/accounts/:account_id/captain/assistant_responses/:id' do
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
      patch "/api/v1/accounts/#{account.id}/captain/assistant_responses/#{response_record.id}",
            params: update_params,
            headers: admin.create_new_auth_token,
            as: :json

      expect(response).to have_http_status(:ok)

      expect(json_response[:question]).to eq('Updated question?')
      expect(json_response[:answer]).to eq('Updated answer')
    end

    it 'does not move a response to an assistant in another account' do
      other_assistant = create(:captain_assistant)
      params = update_params.deep_merge(assistant_response: { assistant_id: other_assistant.id })

      patch "/api/v1/accounts/#{account.id}/captain/assistant_responses/#{response_record.id}",
            params: params,
            headers: admin.create_new_auth_token,
            as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response_record.reload.assistant).to eq(assistant)
      expect(response_record.question).not_to eq('Updated question?')
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
        patch "/api/v1/accounts/#{account.id}/captain/assistant_responses/#{response_record.id}",
              params: invalid_params,
              headers: admin.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'DELETE /api/v1/accounts/:account_id/captain/assistant_responses/:id' do
    let!(:response_record) { create(:captain_assistant_response, assistant: assistant) }

    it 'deletes the response' do
      expect do
        delete "/api/v1/accounts/#{account.id}/captain/assistant_responses/#{response_record.id}",
               headers: admin.create_new_auth_token,
               as: :json
      end.to change(Captain::AssistantResponse, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    context 'with invalid id' do
      it 'returns not found' do
        delete "/api/v1/accounts/#{account.id}/captain/assistant_responses/0",
               headers: admin.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
