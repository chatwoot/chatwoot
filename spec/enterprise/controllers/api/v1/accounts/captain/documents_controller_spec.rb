require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::Captain::Documents', type: :request do
  let(:account) { create(:account, custom_attributes: { plan_name: 'startups' }) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:assistant2) { create(:captain_assistant, account: account) }
  let(:document) { create(:captain_document, assistant: assistant, account: account, status: :available) }
  let(:captain_limits) do
    {
      :startups => { :documents => 1, :responses => 100 }
    }.with_indifferent_access
  end

  def json_response
    JSON.parse(response.body, symbolize_names: true)
  end

  describe 'GET /api/v1/accounts/:account_id/captain/documents' do
    context 'when it is an un-authenticated user' do
      before do
        get "/api/v1/accounts/#{account.id}/captain/documents"
      end

      it 'returns unauthorized status' do
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent' do
      context 'when no filters are applied' do
        before do
          create_list(:captain_document, 30, assistant: assistant, account: account)
        end

        it 'returns the first page of documents' do
          get "/api/v1/accounts/#{account.id}/captain/documents", headers: agent.create_new_auth_token, as: :json

          expect(response).to have_http_status(:ok)
          expect(json_response[:payload].length).to eq(25)
          expect(json_response[:meta]).to eq({ page: 1, total_count: 30 })
        end

        it 'returns the second page of documents' do
          get "/api/v1/accounts/#{account.id}/captain/documents",
              params: { page: 2 },
              headers: agent.create_new_auth_token, as: :json

          expect(response).to have_http_status(:ok)
          expect(json_response[:payload].length).to eq(5)
          expect(json_response[:meta]).to eq({ page: 2, total_count: 30 })
        end

        it 'returns the generated FAQ count for each document' do
          document = create(:captain_document, assistant: assistant, account: account)
          create_list(:captain_assistant_response, 2,
                      assistant: assistant, account: account, documentable: document)

          get "/api/v1/accounts/#{account.id}/captain/documents",
              headers: agent.create_new_auth_token, as: :json

          matching_document = json_response[:payload].find { |item| item[:id] == document.id }
          expect(matching_document[:responses_count]).to eq(2)
        end
      end

      context 'when filtering by assistant_id' do
        before do
          create_list(:captain_document, 3, assistant: assistant, account: account)
          create_list(:captain_document, 2, assistant: assistant2, account: account)
        end

        it 'returns only documents for the specified assistant' do
          get "/api/v1/accounts/#{account.id}/captain/documents",
              params: { assistant_id: assistant.id },
              headers: agent.create_new_auth_token, as: :json
          expect(response).to have_http_status(:ok)
          expect(json_response[:payload].length).to eq(3)
          expect(json_response[:payload][0][:assistant][:id]).to eq(assistant.id)
        end

        it 'returns empty array when assistant has no documents' do
          new_assistant = create(:captain_assistant, account: account)
          get "/api/v1/accounts/#{account.id}/captain/documents",
              params: { assistant_id: new_assistant.id },
              headers: agent.create_new_auth_token, as: :json
          expect(response).to have_http_status(:ok)
          expect(json_response[:payload]).to be_empty
        end
      end

      context 'when documents belong to different accounts' do
        let(:other_account) { create(:account) }

        before do
          create_list(:captain_document, 3, assistant: assistant, account: account)
          create_list(:captain_document, 2, account: other_account)
        end

        it 'only returns documents for the current account' do
          get "/api/v1/accounts/#{account.id}/captain/documents",
              headers: agent.create_new_auth_token, as: :json
          expect(response).to have_http_status(:ok)
          expect(json_response[:payload].length).to eq(3)
          document_account_ids = json_response[:payload].pluck(:account_id).uniq
          expect(document_account_ids).to eq([account.id])
        end
      end

      context 'with pagination and assistant filter combined' do
        before do
          create_list(:captain_document, 30, assistant: assistant, account: account)
          create_list(:captain_document, 10, assistant: assistant2, account: account)
        end

        it 'returns paginated results for specific assistant' do
          get "/api/v1/accounts/#{account.id}/captain/documents",
              params: { assistant_id: assistant.id, page: 2 },
              headers: agent.create_new_auth_token, as: :json
          expect(response).to have_http_status(:ok)
          expect(json_response[:payload].length).to eq(5)
          expect(json_response[:payload][0][:assistant][:id]).to eq(assistant.id)
          expect(json_response[:meta]).to eq({ page: 2, total_count: 30 })
        end
      end

      it 'does not allow conversation usage sorting' do
        get "/api/v1/accounts/#{account.id}/captain/documents",
            params: { sort: 'most_used' },
            headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an admin' do
      it 'returns the distinct conversation usage count for each document' do
        first_conversation = create(:conversation, account: account)
        second_conversation = create(:conversation, account: account)
        other_document = create(:captain_document, assistant: assistant, account: account)

        create(:captain_agent_session, account: account, assistant: assistant,
                                       subject: first_conversation, document_ids: [document.id], credits_consumed: 1.0)
        create(:captain_agent_session, account: account, assistant: assistant,
                                       subject: first_conversation, document_ids: [document.id], credits_consumed: 1.0)
        create(:captain_agent_session, account: account, assistant: assistant,
                                       subject: second_conversation, document_ids: [document.id], credits_consumed: 1.0)
        create(:captain_agent_session, account: account, assistant: assistant,
                                       subject: second_conversation, document_ids: [other_document.id], credits_consumed: 1.0)
        create(:captain_agent_session, account: account, assistant: assistant2,
                                       subject: second_conversation, document_ids: [document.id], credits_consumed: 1.0)

        get "/api/v1/accounts/#{account.id}/captain/documents",
            headers: admin.create_new_auth_token, as: :json

        matching_document = json_response[:payload].find { |item| item[:id] == document.id }
        expect(matching_document[:used_in_conversations_count]).to eq(2)
      end

      it 'excludes handoff sessions from document usage' do
        answered_document = create(:captain_document, assistant: assistant, account: account)
        answered_conversation = create(:conversation, account: account)
        handoff_conversation = create(:conversation, account: account)
        create(:captain_agent_session, account: account, assistant: assistant,
                                       subject: answered_conversation, document_ids: [answered_document.id], credits_consumed: 1.0)
        create(:captain_agent_session, account: account, assistant: assistant,
                                       subject: handoff_conversation, document_ids: [document.id], credits_consumed: 0.0)

        get "/api/v1/accounts/#{account.id}/captain/documents",
            params: { assistant_id: assistant.id, sort: 'most_used' },
            headers: admin.create_new_auth_token, as: :json

        documents_by_id = json_response[:payload].index_by { |item| item[:id] }
        expect(json_response[:payload].first[:id]).to eq(answered_document.id)
        expect(documents_by_id.dig(document.id, :used_in_conversations_count)).to eq(0)

        get "/api/v1/accounts/#{account.id}/captain/documents/#{document.id}/drilldown",
            headers: admin.create_new_auth_token, as: :json

        expect(json_response[:meta][:conversation_count]).to eq(0)
        expect(json_response[:payload]).to be_empty
      end

      it 'sorts documents by the number of distinct conversations that used them' do
        most_used_document = create(:captain_document, assistant: assistant, account: account)
        less_used_document = create(:captain_document, assistant: assistant, account: account)
        unused_document = create(:captain_document, assistant: assistant, account: account)
        first_conversation = create(:conversation, account: account)
        second_conversation = create(:conversation, account: account)

        create(:captain_agent_session, account: account, assistant: assistant,
                                       subject: first_conversation, document_ids: [most_used_document.id], credits_consumed: 1.0)
        create(:captain_agent_session, account: account, assistant: assistant,
                                       subject: first_conversation, document_ids: [most_used_document.id], credits_consumed: 1.0)
        create(:captain_agent_session, account: account, assistant: assistant,
                                       subject: second_conversation, document_ids: [most_used_document.id], credits_consumed: 1.0)
        create(:captain_agent_session, account: account, assistant: assistant,
                                       subject: second_conversation, document_ids: [less_used_document.id], credits_consumed: 1.0)

        get "/api/v1/accounts/#{account.id}/captain/documents",
            params: { assistant_id: assistant.id, sort: 'most_used' },
            headers: admin.create_new_auth_token, as: :json

        expect(response).to have_http_status(:ok)
        expected_document_ids = [most_used_document.id, less_used_document.id, unused_document.id]
        expect(json_response[:payload].pluck(:id)).to eq(expected_document_ids)
        expect(json_response[:payload].pluck(:used_in_conversations_count)).to eq([2, 1, 0])
      end

      it 'returns 25 documents at a time when sorting by usage' do
        create_list(:captain_document, 30, assistant: assistant, account: account)

        get "/api/v1/accounts/#{account.id}/captain/documents",
            params: { assistant_id: assistant.id, sort: 'most_used' },
            headers: admin.create_new_auth_token, as: :json

        expect(json_response[:payload].length).to eq(25)
        expect(json_response[:meta]).to eq({ page: 1, total_count: 30 })
      end

      it 'excludes deleted conversations from usage counts and sorting' do
        used_document = create(:captain_document, assistant: assistant, account: account)
        unused_document = create(:captain_document, assistant: assistant, account: account)
        deleted_conversation = create(:conversation, account: account)
        deleted_session = create(:captain_agent_session, account: account, assistant: assistant,
                                                         subject: deleted_conversation,
                                                         document_ids: [unused_document.id], credits_consumed: 1.0)
        live_conversation = create(:conversation, account: account)
        create(:captain_agent_session, account: account, assistant: assistant,
                                       subject: live_conversation, document_ids: [used_document.id], credits_consumed: 1.0)

        deleted_conversation.destroy!
        expect(deleted_session.reload).to be_present

        get "/api/v1/accounts/#{account.id}/captain/documents",
            params: { assistant_id: assistant.id, sort: 'most_used' },
            headers: admin.create_new_auth_token, as: :json

        documents_by_id = json_response[:payload].index_by { |item| item[:id] }
        expect(json_response[:payload].first[:id]).to eq(used_document.id)
        expect(documents_by_id.dig(used_document.id, :used_in_conversations_count)).to eq(1)
        expect(documents_by_id.dig(unused_document.id, :used_in_conversations_count)).to eq(0)
      end
    end
  end

  describe 'GET /api/v1/accounts/:account_id/captain/documents/:id' do
    context 'when it is an un-authenticated user' do
      before do
        get "/api/v1/accounts/#{account.id}/captain/documents/#{document.id}"
      end

      it 'returns unauthorized status' do
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent' do
      before do
        get "/api/v1/accounts/#{account.id}/captain/documents/#{document.id}",
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

      it 'returns the crawled content for the document' do
        expect(json_response[:content]).to eq(document.content)
      end

      it 'returns sync metadata when the document has been synced' do
        synced_at = 1.hour.ago
        document.update!(sync_status: :synced, last_synced_at: synced_at)

        get "/api/v1/accounts/#{account.id}/captain/documents/#{document.id}",
            headers: agent.create_new_auth_token, as: :json

        expect(json_response[:sync_status]).to eq('synced')
        expect(json_response[:last_synced_at]).to eq(synced_at.to_i)
      end

      it 'does not report failed documents without a successful sync as last synced' do
        document.update!(sync_status: :failed, last_sync_attempted_at: 1.minute.ago)

        get "/api/v1/accounts/#{account.id}/captain/documents/#{document.id}",
            headers: agent.create_new_auth_token, as: :json

        expect(json_response[:sync_status]).to eq('failed')
        expect(json_response[:last_synced_at]).to be_nil
      end
    end
  end

  describe 'GET /api/v1/accounts/:account_id/captain/documents/:id/drilldown' do
    let!(:older_conversation) do
      create(:conversation, account: account, last_activity_at: 2.days.ago)
    end
    let!(:newer_conversation) do
      create(:conversation, account: account, last_activity_at: 1.day.ago)
    end

    before do
      create(:captain_agent_session, account: account, assistant: assistant,
                                     subject: older_conversation, document_ids: [document.id], credits_consumed: 1.0)
      create(:captain_agent_session, account: account, assistant: assistant,
                                     subject: newer_conversation, document_ids: [document.id], credits_consumed: 1.0)
      create(:captain_agent_session, account: account, assistant: assistant,
                                     subject: newer_conversation, document_ids: [document.id], credits_consumed: 1.0)
    end

    it 'returns unauthorized for an agent' do
      get "/api/v1/accounts/#{account.id}/captain/documents/#{document.id}/drilldown",
          headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns distinct conversations through the shared drilldown contract for an admin' do
      get "/api/v1/accounts/#{account.id}/captain/documents/#{document.id}/drilldown",
          params: { per_page: 1 }, headers: admin.create_new_auth_token, as: :json

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

    it 'returns 25 conversations at a time by default' do
      create_list(:conversation, 24, account: account).each do |conversation|
        create(:captain_agent_session, account: account, assistant: assistant,
                                       subject: conversation, document_ids: [document.id], credits_consumed: 1.0)
      end

      get "/api/v1/accounts/#{account.id}/captain/documents/#{document.id}/drilldown",
          headers: admin.create_new_auth_token, as: :json

      expect(json_response[:meta]).to include(current_page: 1, per_page: 25, total_count: 26)
      expect(json_response[:payload].length).to eq(25)
    end

    it 'does not return sessions from another document' do
      other_document = create(:captain_document, assistant: assistant, account: account)

      get "/api/v1/accounts/#{account.id}/captain/documents/#{other_document.id}/drilldown",
          headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response[:meta][:total_count]).to eq(0)
      expect(json_response[:payload]).to be_empty
    end
  end

  describe 'POST /api/v1/accounts/:account_id/captain/documents' do
    let(:valid_attributes) do
      {
        document: {
          name: 'Test Document',
          external_link: 'https://example.com/doc',
          assistant_id: assistant.id
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
        post "/api/v1/accounts/#{account.id}/captain/documents",
             params: valid_attributes, as: :json
      end

      it 'returns unauthorized status' do
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/captain/documents",
             params: valid_attributes,
             headers: agent.create_new_auth_token

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an admin' do
      context 'with valid parameters' do
        it 'creates a new document' do
          expect do
            post "/api/v1/accounts/#{account.id}/captain/documents",
                 params: valid_attributes,
                 headers: admin.create_new_auth_token
          end.to change(Captain::Document, :count).by(1)
        end

        it 'returns success status and the created document' do
          post "/api/v1/accounts/#{account.id}/captain/documents",
               params: valid_attributes,
               headers: admin.create_new_auth_token, as: :json

          expect(response).to have_http_status(:success)
          expect(json_response[:name]).to eq('Test Document')
          expect(json_response[:external_link]).to eq('https://example.com/doc')
        end
      end

      context 'with invalid parameters' do
        before do
          post "/api/v1/accounts/#{account.id}/captain/documents",
               params: invalid_attributes,
               headers: admin.create_new_auth_token
        end

        it 'returns unprocessable entity status' do
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context 'with limits exceeded' do
        before do
          create_list(:captain_document, 5, assistant: assistant, account: account)

          InstallationConfig.find_or_initialize_by(name: 'CAPTAIN_CLOUD_PLAN_LIMITS').update!(value: captain_limits.to_json)
          post "/api/v1/accounts/#{account.id}/captain/documents",
               params: valid_attributes,
               headers: admin.create_new_auth_token
        end

        it 'returns an error' do
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  describe 'POST /api/v1/accounts/:account_id/captain/documents/:id/sync' do
    before { clear_enqueued_jobs }

    context 'when it is an un-authenticated user' do
      it 'returns unauthorized status' do
        post "/api/v1/accounts/#{account.id}/captain/documents/#{document.id}/sync"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent' do
      it 'denies the request' do
        post "/api/v1/accounts/#{account.id}/captain/documents/#{document.id}/sync",
             headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an admin' do
      it 'queues a sync and returns accepted' do
        freeze_time do
          expect do
            post "/api/v1/accounts/#{account.id}/captain/documents/#{document.id}/sync",
                 headers: admin.create_new_auth_token, as: :json
          end.to have_enqueued_job(Captain::Documents::PerformSyncJob).with(document).on_queue('low')

          expect(document.reload).to have_attributes(
            sync_status: 'syncing',
            last_sync_attempted_at: Time.current
          )
        end

        expect(response).to have_http_status(:accepted)
      end

      it 'queues documents that already have a sync in progress' do
        document.update!(sync_status: :syncing, last_sync_attempted_at: 1.minute.ago)

        expect do
          post "/api/v1/accounts/#{account.id}/captain/documents/#{document.id}/sync",
               headers: admin.create_new_auth_token, as: :json
        end.to have_enqueued_job(Captain::Documents::PerformSyncJob).with(document).on_queue('low')

        expect(response).to have_http_status(:accepted)
      end

      it 'queues stale syncing documents again' do
        freeze_time do
          document.update!(sync_status: :syncing, last_sync_attempted_at: (Captain::Document::SYNC_STALE_TIMEOUT + 1.minute).ago)

          expect do
            post "/api/v1/accounts/#{account.id}/captain/documents/#{document.id}/sync",
                 headers: admin.create_new_auth_token, as: :json
          end.to have_enqueued_job(Captain::Documents::PerformSyncJob).with(document)

          expect(document.reload).to have_attributes(
            sync_status: 'syncing',
            last_sync_attempted_at: Time.current
          )
        end

        expect(response).to have_http_status(:accepted)
      end

      it 'rejects PDF documents with an explanatory error' do
        pdf_document = build(:captain_document, assistant: assistant, account: account)
        pdf_document.pdf_file.attach(io: StringIO.new('PDF content'), filename: 'test.pdf',
                                     content_type: 'application/pdf')
        pdf_document.save!

        expect do
          post "/api/v1/accounts/#{account.id}/captain/documents/#{pdf_document.id}/sync",
               headers: admin.create_new_auth_token, as: :json
        end.not_to have_enqueued_job(Captain::Documents::PerformSyncJob)

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'rejects documents that are still being processed' do
        in_progress_document = create(:captain_document, assistant: assistant, account: account, status: :in_progress)

        expect do
          post "/api/v1/accounts/#{account.id}/captain/documents/#{in_progress_document.id}/sync",
               headers: admin.create_new_auth_token, as: :json
        end.not_to have_enqueued_job(Captain::Documents::PerformSyncJob)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'DELETE /api/v1/accounts/:account_id/captain/documents/:id' do
    context 'when it is an un-authenticated user' do
      before do
        delete "/api/v1/accounts/#{account.id}/captain/documents/#{document.id}"
      end

      it 'returns unauthorized status' do
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent' do
      let!(:document_to_delete) { create(:captain_document, assistant: assistant) }

      it 'deletes the document' do
        delete "/api/v1/accounts/#{account.id}/captain/documents/#{document_to_delete.id}",
               headers: agent.create_new_auth_token

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an admin' do
      context 'when document exists' do
        let!(:document_to_delete) { create(:captain_document, assistant: assistant) }

        it 'deletes the document' do
          expect do
            delete "/api/v1/accounts/#{account.id}/captain/documents/#{document_to_delete.id}",
                   headers: admin.create_new_auth_token
          end.to change(Captain::Document, :count).by(-1)
        end

        it 'returns no content status' do
          delete "/api/v1/accounts/#{account.id}/captain/documents/#{document_to_delete.id}",
                 headers: admin.create_new_auth_token

          expect(response).to have_http_status(:no_content)
        end
      end

      context 'when document does not exist' do
        before do
          delete "/api/v1/accounts/#{account.id}/captain/documents/invalid_id",
                 headers: admin.create_new_auth_token
        end

        it 'returns not found status' do
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end
end
