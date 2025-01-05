require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::Captain::Documents', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:document) { create(:captain_document, assistant: assistant, account: account) }

  describe 'GET /api/v1/accounts/:account_id/captain/assistants/:assistant_id/documents' do
    context 'when it is an un-authenticated user' do
      before do
        get "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/documents"
      end

      it 'returns unauthorized status' do
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent' do
      before do
        create_list(:captain_document, 3, assistant: assistant)
        get "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/documents",
            headers: agent.create_new_auth_token
      end

      it 'returns success status' do
        expect(response).to have_http_status(:success)
      end

      it 'returns all documents in descending order' do
        json_response = JSON.parse(response.body)
        expect(json_response.size).to eq(3)
      end
    end
  end

  describe 'GET /api/v1/accounts/:account_id/captain/assistants/:assistant_id/documents/:id' do
    context 'when it is an un-authenticated user' do
      before do
        get "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/documents/#{document.id}"
      end

      it 'returns unauthorized status' do
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent' do
      before do
        get "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/documents/#{document.id}",
            headers: agent.create_new_auth_token
      end

      it 'returns success status' do
        expect(response).to have_http_status(:success)
      end

      it 'returns the requested document' do
        json_response = JSON.parse(response.body)
        expect(json_response['id']).to eq(document.id)
        expect(json_response['name']).to eq(document.name)
        expect(json_response['external_link']).to eq(document.external_link)
      end
    end
  end

  describe 'POST /api/v1/accounts/:account_id/captain/assistants/:assistant_id/documents' do
    let(:valid_attributes) do
      {
        document: {
          name: 'Test Document',
          external_link: 'https://example.com/doc'
        }
      }
    end

    let(:invalid_attributes) do
      {
        document: {
          name: '',
          external_link: ''
        }
      }
    end

    context 'when it is an un-authenticated user' do
      before do
        post "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/documents",
             params: valid_attributes
      end

      it 'returns unauthorized status' do
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/documents",
             params: valid_attributes,
             headers: agent.create_new_auth_token

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an admin' do
      context 'with valid parameters' do
        it 'creates a new document' do
          expect do
            post "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/documents",
                 params: valid_attributes,
                 headers: admin.create_new_auth_token
          end.to change(Captain::Document, :count).by(1)
        end

        it 'returns success status and the created document' do
          post "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/documents",
               params: valid_attributes,
               headers: admin.create_new_auth_token

          expect(response).to have_http_status(:success)
          json_response = JSON.parse(response.body)
          expect(json_response['name']).to eq('Test Document')
          expect(json_response['external_link']).to eq('https://example.com/doc')
        end
      end

      context 'with invalid parameters' do
        before do
          post "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/documents",
               params: invalid_attributes,
               headers: admin.create_new_auth_token
        end

        it 'returns unprocessable entity status' do
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  describe 'DELETE /api/v1/accounts/:account_id/captain/assistants/:assistant_id/documents/:id' do
    context 'when it is an un-authenticated user' do
      before do
        delete "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/documents/#{document.id}"
      end

      it 'returns unauthorized status' do
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent' do
      let!(:document_to_delete) { create(:captain_document, assistant: assistant) }

      it 'deletes the document' do
        delete "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/documents/#{document_to_delete.id}",
               headers: agent.create_new_auth_token

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an admin' do
      context 'when document exists' do
        let!(:document_to_delete) { create(:captain_document, assistant: assistant) }

        it 'deletes the document' do
          expect do
            delete "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/documents/#{document_to_delete.id}",
                   headers: admin.create_new_auth_token
          end.to change(Captain::Document, :count).by(-1)
        end

        it 'returns no content status' do
          delete "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/documents/#{document_to_delete.id}",
                 headers: admin.create_new_auth_token

          expect(response).to have_http_status(:no_content)
        end
      end

      context 'when document does not exist' do
        before do
          delete "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/documents/invalid_id",
                 headers: admin.create_new_auth_token
        end

        it 'returns not found status' do
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end
end
