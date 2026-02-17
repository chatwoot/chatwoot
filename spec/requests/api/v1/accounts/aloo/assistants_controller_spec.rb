# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Aloo Assistants API', type: :request do
  let(:account) { create(:account) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }

  describe 'GET /api/v1/accounts/{account.id}/aloo/assistants' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/aloo/assistants"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated administrator' do
      let!(:assistant) { create(:aloo_assistant, account: account) }

      it 'returns all assistants' do
        get "/api/v1/accounts/#{account.id}/aloo/assistants",
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)

        json_response = response.parsed_body
        expect(json_response['meta']['total_count']).to eq(1)
        expect(json_response['payload']).to be_an(Array)
        expect(json_response['payload'].length).to eq(1)
        expect(json_response['payload'].first['name']).to eq(assistant.name)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/aloo/assistants' do
    let(:valid_params) do
      {
        assistant: {
          name: 'Test Assistant',
          description: 'A test assistant',
          tone: 'friendly',
          formality: 'medium',
          empathy_level: 'medium',
          verbosity: 'balanced',
          emoji_usage: 'minimal',
          greeting_style: 'warm',
          language: 'en'
        }
      }
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/aloo/assistants",
             params: valid_params,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated administrator' do
      it 'creates an assistant with valid params' do
        expect do
          post "/api/v1/accounts/#{account.id}/aloo/assistants",
               headers: administrator.create_new_auth_token,
               params: valid_params,
               as: :json
        end.to change(Aloo::Assistant, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(response.parsed_body['name']).to eq('Test Assistant')
      end

      it 'returns error when name is blank' do
        post "/api/v1/accounts/#{account.id}/aloo/assistants",
             headers: administrator.create_new_auth_token,
             params: { assistant: valid_params[:assistant].merge(name: '') },
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['message']).to include("Name can't be blank")
      end

      it 'returns error when name is missing' do
        post "/api/v1/accounts/#{account.id}/aloo/assistants",
             headers: administrator.create_new_auth_token,
             params: { assistant: valid_params[:assistant].except(:name) },
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'creates assistant with personality settings' do
        post "/api/v1/accounts/#{account.id}/aloo/assistants",
             headers: administrator.create_new_auth_token,
             params: {
               assistant: valid_params[:assistant].merge(
                 tone: 'professional',
                 formality: 'high',
                 empathy_level: 'high'
               )
             },
             as: :json

        expect(response).to have_http_status(:created)
        json_response = response.parsed_body
        expect(json_response['personality']['tone']).to eq('professional')
        expect(json_response['personality']['formality']).to eq('high')
        expect(json_response['personality']['empathy_level']).to eq('high')
      end

      it 'creates assistant with Arabic dialect' do
        post "/api/v1/accounts/#{account.id}/aloo/assistants",
             headers: administrator.create_new_auth_token,
             params: {
               assistant: valid_params[:assistant].merge(
                 language: 'ar',
                 dialect: 'EG'
               )
             },
             as: :json

        expect(response).to have_http_status(:created)
        expect(response.parsed_body['language']).to eq('ar')
        expect(response.parsed_body['dialect']).to eq('EG')
      end
    end

    context 'when it is an authenticated agent' do
      it 'returns forbidden' do
        post "/api/v1/accounts/#{account.id}/aloo/assistants",
             headers: agent.create_new_auth_token,
             params: valid_params,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/aloo/assistants/{id}' do
    let!(:assistant) { create(:aloo_assistant, account: account, name: 'Original Name') }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch "/api/v1/accounts/#{account.id}/aloo/assistants/#{assistant.id}",
              params: { assistant: { name: 'Updated Name' } },
              as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated administrator' do
      it 'updates the assistant name' do
        patch "/api/v1/accounts/#{account.id}/aloo/assistants/#{assistant.id}",
              headers: administrator.create_new_auth_token,
              params: { assistant: { name: 'Updated Name' } },
              as: :json

        expect(response).to have_http_status(:ok)
        expect(assistant.reload.name).to eq('Updated Name')
      end

      it 'updates personality settings' do
        patch "/api/v1/accounts/#{account.id}/aloo/assistants/#{assistant.id}",
              headers: administrator.create_new_auth_token,
              params: { assistant: { tone: 'professional', formality: 'high' } },
              as: :json

        expect(response).to have_http_status(:ok)
        expect(assistant.reload.tone).to eq('professional')
        expect(assistant.reload.formality).to eq('high')
      end

      it 'returns error for invalid tone' do
        patch "/api/v1/accounts/#{account.id}/aloo/assistants/#{assistant.id}",
              headers: administrator.create_new_auth_token,
              params: { assistant: { tone: 'invalid_tone' } },
              as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/aloo/assistants/{id}' do
    let!(:assistant) { create(:aloo_assistant, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/aloo/assistants/#{assistant.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated administrator' do
      it 'deletes the assistant' do
        expect do
          delete "/api/v1/accounts/#{account.id}/aloo/assistants/#{assistant.id}",
                 headers: administrator.create_new_auth_token,
                 as: :json
        end.to change(Aloo::Assistant, :count).by(-1)

        expect(response).to have_http_status(:ok)
      end
    end

    context 'when it is an authenticated agent' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/aloo/assistants/#{assistant.id}",
               headers: agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when assistant belongs to another account' do
      let(:other_account) { create(:account) }
      let!(:other_assistant) { create(:aloo_assistant, account: other_account) }

      it 'returns not found' do
        delete "/api/v1/accounts/#{account.id}/aloo/assistants/#{other_assistant.id}",
               headers: administrator.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when assistant does not exist' do
      it 'returns not found' do
        delete "/api/v1/accounts/#{account.id}/aloo/assistants/999999",
               headers: administrator.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when assistant has associated records' do
      let!(:inbox) { create(:inbox, account: account) }
      let!(:assistant_inbox) { create(:aloo_assistant_inbox, assistant: assistant, inbox: inbox) }
      let!(:document) { create(:aloo_document, assistant: assistant, account: account) }
      let!(:embedding) { create(:aloo_embedding, assistant: assistant, account: account, document: document) }
      let!(:conversation) { create(:conversation, account: account) }
      let!(:message) { create(:message, conversation: conversation, sender: assistant, account: account, message_type: :outgoing) }

      it 'destroys associated assistant_inboxes but keeps the inbox' do
        expect do
          delete "/api/v1/accounts/#{account.id}/aloo/assistants/#{assistant.id}",
                 headers: administrator.create_new_auth_token,
                 as: :json
        end.to change(Aloo::AssistantInbox, :count).by(-1)
           .and not_change(Inbox, :count)

        expect(response).to have_http_status(:ok)
        expect(Inbox.exists?(inbox.id)).to be true
      end

      it 'destroys associated documents' do
        expect do
          delete "/api/v1/accounts/#{account.id}/aloo/assistants/#{assistant.id}",
                 headers: administrator.create_new_auth_token,
                 as: :json
        end.to change(Aloo::Document, :count).by(-1)

        expect(response).to have_http_status(:ok)
      end

      it 'destroys associated embeddings' do
        expect do
          delete "/api/v1/accounts/#{account.id}/aloo/assistants/#{assistant.id}",
                 headers: administrator.create_new_auth_token,
                 as: :json
        end.to change(Aloo::Embedding, :count).by(-1)

        expect(response).to have_http_status(:ok)
      end

      it 'nullifies sender_id on associated messages' do
        delete "/api/v1/accounts/#{account.id}/aloo/assistants/#{assistant.id}",
               headers: administrator.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:ok)
        expect(Message.exists?(message.id)).to be true
        expect(message.reload.sender_id).to be_nil
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/aloo/assistants/{id}' do
    let!(:assistant) { create(:aloo_assistant, account: account) }

    context 'when it is an authenticated administrator' do
      it 'returns the assistant details' do
        get "/api/v1/accounts/#{account.id}/aloo/assistants/#{assistant.id}",
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['id']).to eq(assistant.id)
        expect(response.parsed_body['name']).to eq(assistant.name)
        expect(response.parsed_body['personality']).to be_present
        expect(response.parsed_body['features']).to be_present
      end
    end

    context 'when assistant does not exist' do
      it 'returns not found' do
        get "/api/v1/accounts/#{account.id}/aloo/assistants/999999",
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when accessing another account assistant' do
      let(:other_account) { create(:account) }
      let!(:other_assistant) { create(:aloo_assistant, account: other_account) }

      it 'returns not found' do
        get "/api/v1/accounts/#{account.id}/aloo/assistants/#{other_assistant.id}",
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/aloo/assistants/{id}/assign_inbox' do
    let!(:assistant) { create(:aloo_assistant, account: account) }
    let!(:inbox) { create(:inbox, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/aloo/assistants/#{assistant.id}/assign_inbox",
             params: { inbox_id: inbox.id },
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated administrator' do
      it 'assigns the assistant to an inbox' do
        expect do
          post "/api/v1/accounts/#{account.id}/aloo/assistants/#{assistant.id}/assign_inbox",
               headers: administrator.create_new_auth_token,
               params: { inbox_id: inbox.id },
               as: :json
        end.to change(Aloo::AssistantInbox, :count).by(1)

        expect(response).to have_http_status(:ok)

        json_response = response.parsed_body
        expect(json_response['id']).to eq(assistant.id)
        expect(json_response['assigned_inboxes']).to be_an(Array)
        expect(json_response['assigned_inboxes'].map { |i| i['id'] }).to include(inbox.id)
      end

      it 'replaces existing assistant assignment on the same inbox' do
        other_assistant = create(:aloo_assistant, account: account)
        create(:aloo_assistant_inbox, assistant: other_assistant, inbox: inbox)

        expect do
          post "/api/v1/accounts/#{account.id}/aloo/assistants/#{assistant.id}/assign_inbox",
               headers: administrator.create_new_auth_token,
               params: { inbox_id: inbox.id },
               as: :json
        end.not_to change(Aloo::AssistantInbox, :count)

        expect(response).to have_http_status(:ok)

        # Verify old assignment is removed and new one is created
        expect(Aloo::AssistantInbox.find_by(inbox: inbox).assistant).to eq(assistant)
        expect(other_assistant.reload.inboxes).not_to include(inbox)
      end

      it 'returns the full assistant object with assigned_inboxes' do
        post "/api/v1/accounts/#{account.id}/aloo/assistants/#{assistant.id}/assign_inbox",
             headers: administrator.create_new_auth_token,
             params: { inbox_id: inbox.id },
             as: :json

        expect(response).to have_http_status(:ok)

        json_response = response.parsed_body
        expect(json_response).to include(
          'id' => assistant.id,
          'name' => assistant.name,
          'personality' => be_present,
          'features' => be_present,
          'assigned_inboxes' => be_an(Array)
        )
      end

      it 'returns not found for non-existent inbox' do
        post "/api/v1/accounts/#{account.id}/aloo/assistants/#{assistant.id}/assign_inbox",
             headers: administrator.create_new_auth_token,
             params: { inbox_id: 999_999 },
             as: :json

        expect(response).to have_http_status(:not_found)
      end

      it 'returns not found for inbox from another account' do
        other_account = create(:account)
        other_inbox = create(:inbox, account: other_account)

        post "/api/v1/accounts/#{account.id}/aloo/assistants/#{assistant.id}/assign_inbox",
             headers: administrator.create_new_auth_token,
             params: { inbox_id: other_inbox.id },
             as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when it is an authenticated agent' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/aloo/assistants/#{assistant.id}/assign_inbox",
             headers: agent.create_new_auth_token,
             params: { inbox_id: inbox.id },
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/aloo/assistants/{id}/unassign_inbox' do
    let!(:assistant) { create(:aloo_assistant, account: account) }
    let!(:inbox) { create(:inbox, account: account) }
    let!(:assistant_inbox) { create(:aloo_assistant_inbox, assistant: assistant, inbox: inbox) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/aloo/assistants/#{assistant.id}/unassign_inbox",
               params: { inbox_id: inbox.id },
               as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated administrator' do
      it 'removes the assistant from the inbox' do
        expect do
          delete "/api/v1/accounts/#{account.id}/aloo/assistants/#{assistant.id}/unassign_inbox",
                 headers: administrator.create_new_auth_token,
                 params: { inbox_id: inbox.id },
                 as: :json
        end.to change(Aloo::AssistantInbox, :count).by(-1)

        expect(response).to have_http_status(:ok)
      end

      it 'returns the full assistant object with updated assigned_inboxes' do
        delete "/api/v1/accounts/#{account.id}/aloo/assistants/#{assistant.id}/unassign_inbox",
               headers: administrator.create_new_auth_token,
               params: { inbox_id: inbox.id },
               as: :json

        expect(response).to have_http_status(:ok)

        json_response = response.parsed_body
        expect(json_response['id']).to eq(assistant.id)
        expect(json_response['assigned_inboxes']).to be_an(Array)
        expect(json_response['assigned_inboxes'].map { |i| i['id'] }).not_to include(inbox.id)
      end

      it 'succeeds even if no assignment exists' do
        assistant_inbox.destroy!

        delete "/api/v1/accounts/#{account.id}/aloo/assistants/#{assistant.id}/unassign_inbox",
               headers: administrator.create_new_auth_token,
               params: { inbox_id: inbox.id },
               as: :json

        expect(response).to have_http_status(:ok)
      end

      it 'returns not found for non-existent inbox' do
        delete "/api/v1/accounts/#{account.id}/aloo/assistants/#{assistant.id}/unassign_inbox",
               headers: administrator.create_new_auth_token,
               params: { inbox_id: 999_999 },
               as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when it is an authenticated agent' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/aloo/assistants/#{assistant.id}/unassign_inbox",
               headers: agent.create_new_auth_token,
               params: { inbox_id: inbox.id },
               as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
