require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::Aiagent::Documents', type: :request do
  let(:account) { create(:account, custom_attributes: { plan_name: 'startups' }) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:topic) { create(:aiagent_topic, account: account) }
  let(:topic2) { create(:aiagent_topic, account: account) }
  let(:document) { create(:aiagent_document, topic: topic, account: account) }
  let(:aiagent_limits) do
    {
      :startups => { :documents => 1, :responses => 100 }
    }.with_indifferent_access
  end

  def json_response
    JSON.parse(response.body, symbolize_names: true)
  end

  describe 'GET /api/v1/accounts/:account_id/aiagent/documents' do
    context 'when it is an un-authenticated user' do
      before do
        get "/api/v1/accounts/#{account.id}/aiagent/documents"
      end

      it 'returns unauthorized status' do
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent' do
      context 'when no filters are applied' do
        before do
          create_list(:aiagent_document, 30, topic: topic, account: account)
        end

        it 'returns the first page of documents' do
          get "/api/v1/accounts/#{account.id}/aiagent/documents", headers: agent.create_new_auth_token, as: :json

          expect(response).to have_http_status(:ok)
          expect(json_response[:payload].length).to eq(25)
          expect(json_response[:meta]).to eq({ page: 1, total_count: 30 })
        end

        it 'returns the second page of documents' do
          get "/api/v1/accounts/#{account.id}/aiagent/documents",
              params: { page: 2 },
              headers: agent.create_new_auth_token, as: :json

          expect(response).to have_http_status(:ok)
          expect(json_response[:payload].length).to eq(5)
          expect(json_response[:meta]).to eq({ page: 2, total_count: 30 })
        end
      end

      context 'when filtering by topic_id' do
        before do
          create_list(:aiagent_document, 3, topic: topic, account: account)
          create_list(:aiagent_document, 2, topic: topic2, account: account)
        end

        it 'returns only documents for the specified topic' do
          get "/api/v1/accounts/#{account.id}/aiagent/documents",
              params: { topic_id: topic.id },
              headers: agent.create_new_auth_token, as: :json
          expect(response).to have_http_status(:ok)
          expect(json_response[:payload].length).to eq(3)
          expect(json_response[:payload][0][:topic][:id]).to eq(topic.id)
        end

        it 'returns empty array when topic has no documents' do
          new_topic = create(:aiagent_topic, account: account)
          get "/api/v1/accounts/#{account.id}/aiagent/documents",
              params: { topic_id: new_topic.id },
              headers: agent.create_new_auth_token, as: :json
          expect(response).to have_http_status(:ok)
          expect(json_response[:payload]).to be_empty
        end
      end

      context 'when documents belong to different accounts' do
        let(:other_account) { create(:account) }

        before do
          create_list(:aiagent_document, 3, topic: topic, account: account)
          create_list(:aiagent_document, 2, account: other_account)
        end

        it 'only returns documents for the current account' do
          get "/api/v1/accounts/#{account.id}/aiagent/documents",
              headers: agent.create_new_auth_token, as: :json
          expect(response).to have_http_status(:ok)
          expect(json_response[:payload].length).to eq(3)
          document_account_ids = json_response[:payload].pluck(:account_id).uniq
          expect(document_account_ids).to eq([account.id])
        end
      end

      context 'with pagination and topic filter combined' do
        before do
          create_list(:aiagent_document, 30, topic: topic, account: account)
          create_list(:aiagent_document, 10, topic: topic2, account: account)
        end

        it 'returns paginated results for specific topic' do
          get "/api/v1/accounts/#{account.id}/aiagent/documents",
              params: { topic_id: topic.id, page: 2 },
              headers: agent.create_new_auth_token, as: :json
          expect(response).to have_http_status(:ok)
          expect(json_response[:payload].length).to eq(5)
          expect(json_response[:payload][0][:topic][:id]).to eq(topic.id)
          expect(json_response[:meta]).to eq({ page: 2, total_count: 30 })
        end
      end
    end
  end

  describe 'GET /api/v1/accounts/:account_id/aiagent/documents/:id' do
    context 'when it is an un-authenticated user' do
      before do
        get "/api/v1/accounts/#{account.id}/aiagent/documents/#{document.id}"
      end

      it 'returns unauthorized status' do
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent' do
      before do
        get "/api/v1/accounts/#{account.id}/aiagent/documents/#{document.id}",
            headers: agent.create_new_auth_token, as: :json
      end

      it 'returns success status' do
        expect(response).to have_http_status(:success)
      end

      it 'returns the requested document' do
        expect(json_response[:id]).to eq(document.id)
        expect(json_response[:name]).to eq(document.name)
        expect(json_response[:external_link]).to eq(document.external_link)
      end
    end
  end

  describe 'POST /api/v1/accounts/:account_id/aiagent/documents' do
    let(:valid_attributes) do
      {
        document: {
          name: 'Test Document',
          external_link: 'https://example.com/doc',
          topic_id: topic.id
        }
      }
    end

    let(:invalid_attributes) do
      {
        document: {
          name: 'Test Document',
          external_link: 'https://example.com/doc'
        }
      }
    end

    context 'when it is an un-authenticated user' do
      before do
        post "/api/v1/accounts/#{account.id}/aiagent/documents",
             params: valid_attributes, as: :json
      end

      it 'returns unauthorized status' do
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/aiagent/documents",
             params: valid_attributes,
             headers: agent.create_new_auth_token

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an admin' do
      context 'with valid parameters' do
        it 'creates a new document' do
          expect do
            post "/api/v1/accounts/#{account.id}/aiagent/documents",
                 params: valid_attributes,
                 headers: admin.create_new_auth_token
          end.to change(Aiagent::Document, :count).by(1)
        end

        it 'returns success status and the created document' do
          post "/api/v1/accounts/#{account.id}/aiagent/documents",
               params: valid_attributes,
               headers: admin.create_new_auth_token, as: :json

          expect(response).to have_http_status(:success)
          expect(json_response[:name]).to eq('Test Document')
          expect(json_response[:external_link]).to eq('https://example.com/doc')
        end
      end

      context 'with invalid parameters' do
        before do
          post "/api/v1/accounts/#{account.id}/aiagent/documents",
               params: invalid_attributes,
               headers: admin.create_new_auth_token
        end

        it 'returns unprocessable entity status' do
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context 'with limits exceeded' do
        before do
          create_list(:aiagent_document, 5, topic: topic, account: account)

          create(:installation_config, name: 'AIAGENT_CLOUD_PLAN_LIMITS', value: aiagent_limits.to_json)
          post "/api/v1/accounts/#{account.id}/aiagent/documents",
               params: valid_attributes,
               headers: admin.create_new_auth_token
        end

        it 'returns an error' do
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  describe 'DELETE /api/v1/accounts/:account_id/aiagent/documents/:id' do
    context 'when it is an un-authenticated user' do
      before do
        delete "/api/v1/accounts/#{account.id}/aiagent/documents/#{document.id}"
      end

      it 'returns unauthorized status' do
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent' do
      let!(:document_to_delete) { create(:aiagent_document, topic: topic) }

      it 'deletes the document' do
        delete "/api/v1/accounts/#{account.id}/aiagent/documents/#{document_to_delete.id}",
               headers: agent.create_new_auth_token

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an admin' do
      context 'when document exists' do
        let!(:document_to_delete) { create(:aiagent_document, topic: topic) }

        it 'deletes the document' do
          expect do
            delete "/api/v1/accounts/#{account.id}/aiagent/documents/#{document_to_delete.id}",
                   headers: admin.create_new_auth_token
          end.to change(Aiagent::Document, :count).by(-1)
        end

        it 'returns no content status' do
          delete "/api/v1/accounts/#{account.id}/aiagent/documents/#{document_to_delete.id}",
                 headers: admin.create_new_auth_token

          expect(response).to have_http_status(:no_content)
        end
      end

      context 'when document does not exist' do
        before do
          delete "/api/v1/accounts/#{account.id}/aiagent/documents/invalid_id",
                 headers: admin.create_new_auth_token
        end

        it 'returns not found status' do
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end
end
