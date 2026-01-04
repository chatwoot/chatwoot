# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Attachments API', type: :request do
  include ActiveJob::TestHelper

  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:assistant) { create(:aloo_assistant, :with_voice_input, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:message) { create(:message, conversation: conversation, account: account) }
  let(:admin) { create(:user, account: account, role: :administrator) }

  before do
    inbox.update!(aloo_assistant: assistant)
  end

  describe 'POST /api/v1/accounts/:account_id/conversations/:conversation_id/messages/:message_id/attachments/:id/retranscribe' do
    let(:audio_attachment) { create(:attachment, message: message, file_type: :audio) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/messages/#{message.id}/attachments/#{audio_attachment.id}/retranscribe"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      context 'with audio attachment' do
        it 'queues transcription job and returns queued status' do
          expect do
            post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/messages/#{message.id}/attachments/#{audio_attachment.id}/retranscribe",
                 headers: admin.create_new_auth_token,
                 as: :json
          end.to have_enqueued_job(Aloo::AudioTranscriptionJob).with(audio_attachment.id, trigger_response: false)

          expect(response).to have_http_status(:success)
          data = response.parsed_body

          expect(data['status']).to eq('queued')
          expect(data['message']).to include('queued for processing')
          expect(data['attachment_id']).to eq(audio_attachment.id)
        end

        it 'resets transcription status to pending' do
          audio_attachment.update!(meta: { 'transcription_status' => 'completed', 'transcribed_text' => 'Old text' })

          post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/messages/#{message.id}/attachments/#{audio_attachment.id}/retranscribe",
               headers: admin.create_new_auth_token,
               as: :json

          audio_attachment.reload
          expect(audio_attachment.meta['transcription_status']).to eq('pending')
        end

        it 'removes previous transcription error' do
          audio_attachment.update!(meta: { 'transcription_status' => 'failed', 'transcription_error' => 'API error' })

          post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/messages/#{message.id}/attachments/#{audio_attachment.id}/retranscribe",
               headers: admin.create_new_auth_token,
               as: :json

          audio_attachment.reload
          expect(audio_attachment.meta['transcription_error']).to be_nil
        end
      end

      context 'with non-audio attachment' do
        let(:image_attachment) { create(:attachment, message: message, file_type: :image) }

        it 'returns unprocessable entity' do
          post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/messages/#{message.id}/attachments/#{image_attachment.id}/retranscribe",
               headers: admin.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.parsed_body['error']).to include('Only audio attachments')
        end
      end

      context 'when voice transcription is not enabled' do
        before do
          assistant.update!(voice_input_enabled: false)
        end

        it 'returns unprocessable entity' do
          post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/messages/#{message.id}/attachments/#{audio_attachment.id}/retranscribe",
               headers: admin.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.parsed_body['error']).to include('not enabled')
        end
      end
    end
  end

  describe 'GET /api/v1/accounts/:account_id/conversations/:conversation_id/messages/:message_id/attachments/:id/transcription' do
    let(:audio_attachment) { create(:attachment, message: message, file_type: :audio) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/messages/#{message.id}/attachments/#{audio_attachment.id}/transcription"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      context 'with audio attachment' do
        context 'with completed transcription' do
          before do
            audio_attachment.update!(meta: {
                                       'transcription_status' => 'completed',
                                       'transcribed_text' => 'Hello, this is a test',
                                       'transcription_updated_at' => Time.current.iso8601
                                     })
          end

          it 'returns transcription data' do
            get "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/messages/#{message.id}/attachments/#{audio_attachment.id}/transcription",
                headers: admin.create_new_auth_token,
                as: :json

            expect(response).to have_http_status(:success)
            data = response.parsed_body

            expect(data['attachment_id']).to eq(audio_attachment.id)
            expect(data['status']).to eq('completed')
            expect(data['transcribed_text']).to eq('Hello, this is a test')
            expect(data['updated_at']).to be_present
          end
        end

        context 'with pending transcription' do
          before do
            audio_attachment.update!(meta: { 'transcription_status' => 'pending' })
          end

          it 'returns pending status' do
            get "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/messages/#{message.id}/attachments/#{audio_attachment.id}/transcription",
                headers: admin.create_new_auth_token,
                as: :json

            expect(response).to have_http_status(:success)
            data = response.parsed_body

            expect(data['status']).to eq('pending')
            expect(data['transcribed_text']).to be_nil
          end
        end

        context 'with failed transcription' do
          before do
            audio_attachment.update!(meta: {
                                       'transcription_status' => 'failed',
                                       'transcription_error' => 'API error'
                                     })
          end

          it 'returns failed status with error' do
            get "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/messages/#{message.id}/attachments/#{audio_attachment.id}/transcription",
                headers: admin.create_new_auth_token,
                as: :json

            expect(response).to have_http_status(:success)
            data = response.parsed_body

            expect(data['status']).to eq('failed')
            expect(data['error']).to eq('API error')
          end
        end

        context 'with no transcription' do
          it 'returns none status' do
            get "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/messages/#{message.id}/attachments/#{audio_attachment.id}/transcription",
                headers: admin.create_new_auth_token,
                as: :json

            expect(response).to have_http_status(:success)
            data = response.parsed_body

            expect(data['status']).to eq('none')
            expect(data['transcribed_text']).to be_nil
          end
        end
      end

      context 'with non-audio attachment' do
        let(:image_attachment) { create(:attachment, message: message, file_type: :image) }

        it 'returns unprocessable entity' do
          get "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/messages/#{message.id}/attachments/#{image_attachment.id}/transcription",
              headers: admin.create_new_auth_token,
              as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.parsed_body['error']).to include('Only audio attachments')
        end
      end
    end
  end
end
