require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::Captain::BulkActions', type: :request do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let!(:pending_responses) do
    create_list(
      :captain_assistant_response,
      2,
      assistant: assistant,
      account: account,
      status: 'pending'
    )
  end
  let!(:documents) do
    create_list(
      :captain_document,
      2,
      assistant: assistant,
      account: account,
      status: :available
    )
  end

  def json_response
    JSON.parse(response.body, symbolize_names: true)
  end

  describe 'POST /api/v1/accounts/:account_id/captain/bulk_actions' do
    context 'when approving responses' do
      let(:valid_params) do
        {
          type: 'AssistantResponse',
          ids: pending_responses.map(&:id),
          fields: { status: 'approve' }
        }
      end

      it 'approves the responses and returns the updated records' do
        post "/api/v1/accounts/#{account.id}/captain/bulk_actions",
             params: valid_params,
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response).to be_an(Array)
        expect(json_response.length).to eq(2)

        # Verify responses were approved
        pending_responses.each do |response|
          expect(response.reload.status).to eq('approved')
        end
      end
    end

    context 'when deleting responses' do
      let(:delete_params) do
        {
          type: 'AssistantResponse',
          ids: pending_responses.map(&:id),
          fields: { status: 'delete' }
        }
      end

      it 'deletes the responses and returns an empty array' do
        expect do
          post "/api/v1/accounts/#{account.id}/captain/bulk_actions",
               params: delete_params,
               headers: admin.create_new_auth_token,
               as: :json
        end.to change(Captain::AssistantResponse, :count).by(-2)

        expect(response).to have_http_status(:ok)
        expect(json_response).to eq([])

        # Verify responses were deleted
        pending_responses.each do |response|
          expect { response.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    context 'with invalid type' do
      let(:invalid_params) do
        {
          type: 'InvalidType',
          ids: pending_responses.map(&:id),
          fields: { status: 'approve' }
        }
      end

      it 'returns unprocessable entity status' do
        post "/api/v1/accounts/#{account.id}/captain/bulk_actions",
             params: invalid_params,
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response[:success]).to be(false)

        # Verify no changes were made
        pending_responses.each do |response|
          expect(response.reload.status).to eq('pending')
        end
      end
    end

    context 'when deleting documents' do
      let(:document_delete_params) do
        {
          type: 'AssistantDocument',
          ids: documents.map(&:id),
          fields: { status: 'delete' }
        }
      end

      it 'deletes the documents and returns the deleted count' do
        expect do
          post "/api/v1/accounts/#{account.id}/captain/bulk_actions",
               params: document_delete_params,
               headers: admin.create_new_auth_token,
               as: :json
        end.to change(Captain::Document, :count).by(-2)

        expect(response).to have_http_status(:ok)
        expect(json_response).to eq({ count: documents.size })
      end
    end

    context 'when syncing documents' do
      let(:sync_params) do
        {
          type: 'AssistantDocument',
          ids: documents.map(&:id),
          fields: { status: 'sync' }
        }
      end

      before { clear_enqueued_jobs }

      it 'queues a sync for each web document and returns the enqueued document ids' do
        freeze_time do
          expect do
            post "/api/v1/accounts/#{account.id}/captain/bulk_actions",
                 params: sync_params,
                 headers: admin.create_new_auth_token,
                 as: :json
          end.to have_enqueued_job(Captain::Documents::PerformSyncJob).exactly(documents.size).times

          documents.each do |document|
            expect(document.reload).to have_attributes(
              sync_status: 'syncing',
              last_sync_attempted_at: Time.current
            )
          end
        end

        expect(response).to have_http_status(:ok)
        expect(json_response).to eq({ ids: documents.map(&:id), count: documents.size })
      end

      it 'skips PDF documents because they are not syncable' do
        pdf_document = build(:captain_document, assistant: assistant, account: account)
        pdf_document.pdf_file.attach(io: StringIO.new('PDF content'), filename: 'test.pdf',
                                     content_type: 'application/pdf')
        pdf_document.save!

        expect do
          post "/api/v1/accounts/#{account.id}/captain/bulk_actions",
               params: sync_params.merge(ids: [pdf_document.id]),
               headers: admin.create_new_auth_token,
               as: :json
        end.not_to have_enqueued_job(Captain::Documents::PerformSyncJob)

        expect(response).to have_http_status(:ok)
      end

      it 'skips documents that are still being processed' do
        in_progress_document = create(:captain_document, assistant: assistant, account: account, status: :in_progress)

        expect do
          post "/api/v1/accounts/#{account.id}/captain/bulk_actions",
               params: sync_params.merge(ids: [in_progress_document.id]),
               headers: admin.create_new_auth_token,
               as: :json
        end.not_to have_enqueued_job(Captain::Documents::PerformSyncJob)

        expect(response).to have_http_status(:ok)
      end

      it 'skips documents that already have a sync in progress' do
        syncing_document = create(:captain_document, assistant: assistant, account: account, status: :available)
        syncing_document.update!(sync_status: :syncing, last_sync_attempted_at: 1.minute.ago)

        expect do
          post "/api/v1/accounts/#{account.id}/captain/bulk_actions",
               params: sync_params.merge(ids: [syncing_document.id]),
               headers: admin.create_new_auth_token,
               as: :json
        end.not_to have_enqueued_job(Captain::Documents::PerformSyncJob)

        expect(response).to have_http_status(:ok)
      end

      it 'queues stale syncing documents again' do
        syncing_document = create(:captain_document, assistant: assistant, account: account, status: :available)

        freeze_time do
          syncing_document.update!(
            sync_status: :syncing,
            last_sync_attempted_at: (Captain::Document::SYNC_STALE_TIMEOUT + 1.minute).ago
          )

          expect do
            post "/api/v1/accounts/#{account.id}/captain/bulk_actions",
                 params: sync_params.merge(ids: [syncing_document.id]),
                 headers: admin.create_new_auth_token,
                 as: :json
          end.to have_enqueued_job(Captain::Documents::PerformSyncJob).with(syncing_document)

          expect(syncing_document.reload).to have_attributes(
            sync_status: 'syncing',
            last_sync_attempted_at: Time.current
          )
        end

        expect(response).to have_http_status(:ok)
        expect(json_response).to eq({ ids: [syncing_document.id], count: 1 })
      end

      it 'denies non-administrators' do
        post "/api/v1/accounts/#{account.id}/captain/bulk_actions",
             params: sync_params,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with missing parameters' do
      let(:missing_params) do
        {
          type: 'AssistantResponse',
          fields: { status: 'approve' }
        }
      end

      it 'returns unprocessable entity status' do
        post "/api/v1/accounts/#{account.id}/captain/bulk_actions",
             params: missing_params,
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response[:success]).to be(false)

        # Verify no changes were made
        pending_responses.each do |response|
          expect(response.reload.status).to eq('pending')
        end
      end
    end

    context 'with unauthorized user' do
      let(:unauthorized_user) { create(:user, account: create(:account)) }

      it 'returns unauthorized status' do
        post "/api/v1/accounts/#{account.id}/captain/bulk_actions",
             params: { type: 'AssistantResponse', ids: [1], fields: { status: 'approve' } },
             headers: unauthorized_user.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unauthorized)

        # Verify no changes were made
        pending_responses.each do |response|
          expect(response.reload.status).to eq('pending')
        end
      end
    end
  end
end
