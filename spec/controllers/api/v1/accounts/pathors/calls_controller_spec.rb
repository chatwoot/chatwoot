require 'rails_helper'

RSpec.describe 'Pathors Calls API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:conversation) { create(:conversation, account: account) }

  let(:create_payload) do
    {
      conversation_id: conversation.display_id,
      provider_call_id: 'pathors-call-1',
      direction: 'inbound',
      from_number: '+886912345678',
      to_number: '+886222222222',
      started_at: '2026-08-05T10:00:00Z'
    }
  end

  describe 'POST /api/v1/accounts/{account.id}/pathors/calls' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/pathors/calls", params: create_payload, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/pathors/calls",
             params: create_payload, headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an administrator' do
      it 'creates a pathors call and a voice_call message' do
        expect do
          post "/api/v1/accounts/#{account.id}/pathors/calls",
               params: create_payload, headers: admin.create_new_auth_token, as: :json
        end.to change(Call, :count).by(1)

        expect(response).to have_http_status(:success)

        call = Call.last
        expect(call.provider).to eq('pathors')
        expect(call.direction).to eq('incoming')
        expect(call.status).to eq('in_progress')
        expect(call.from_number).to eq('+886912345678')
        expect(call.message).to be_present
      end

      it 'creates an incoming voice_call message for an inbound call' do
        post "/api/v1/accounts/#{account.id}/pathors/calls",
             params: create_payload, headers: admin.create_new_auth_token, as: :json

        message = Call.last.message
        expect(message.content_type).to eq('voice_call')
        expect(message.message_type).to eq('incoming')
        expect(message.conversation_id).to eq(conversation.id)
      end

      it 'creates an outgoing voice_call message for an outbound call' do
        post "/api/v1/accounts/#{account.id}/pathors/calls",
             params: create_payload.merge(direction: 'outbound'),
             headers: admin.create_new_auth_token, as: :json

        call = Call.last
        expect(call.direction).to eq('outgoing')
        expect(call.message.message_type).to eq('outgoing')
      end

      it 'responds with the push event payload plus the message id' do
        post "/api/v1/accounts/#{account.id}/pathors/calls",
             params: create_payload, headers: admin.create_new_auth_token, as: :json

        call = Call.last
        body = response.parsed_body
        expect(body['id']).to eq(call.id)
        expect(body['status']).to eq('in-progress')
        expect(body['direction']).to eq('incoming')
        expect(body['accepted_by_agent_name']).to eq('Pathors AI')
        expect(body['message_id']).to eq(call.message_id)
      end

      it 'is idempotent for a repeated provider_call_id' do
        post "/api/v1/accounts/#{account.id}/pathors/calls",
             params: create_payload, headers: admin.create_new_auth_token, as: :json
        first_id = response.parsed_body['id']

        expect do
          post "/api/v1/accounts/#{account.id}/pathors/calls",
               params: create_payload, headers: admin.create_new_auth_token, as: :json
        end.not_to change(Call, :count)

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['id']).to eq(first_id)
      end

      it 'rejects an unknown direction' do
        post "/api/v1/accounts/#{account.id}/pathors/calls",
             params: create_payload.merge(direction: 'sideways'),
             headers: admin.create_new_auth_token, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns not found for a conversation outside the account' do
        post "/api/v1/accounts/#{account.id}/pathors/calls",
             params: create_payload.merge(conversation_id: conversation.display_id + 9999),
             headers: admin.create_new_auth_token, as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/pathors/calls/{id}' do
    let(:message) do
      create(:message, account: account, conversation: conversation, inbox: conversation.inbox, content_type: 'voice_call')
    end
    let(:call) do
      create(:call, :pathors, account: account, conversation: conversation, inbox: conversation.inbox,
                              contact: conversation.contact, message: message)
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch "/api/v1/accounts/#{account.id}/pathors/calls/#{call.id}", params: { status: 'completed' }, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent' do
      it 'returns unauthorized' do
        patch "/api/v1/accounts/#{account.id}/pathors/calls/#{call.id}",
              params: { status: 'completed' }, headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an administrator' do
      it 'updates the status, duration and end reason' do
        patch "/api/v1/accounts/#{account.id}/pathors/calls/#{call.id}",
              params: { status: 'completed', duration_seconds: 42, end_reason: 'hangup', ended_at: '2026-08-05T10:05:00Z' },
              headers: admin.create_new_auth_token, as: :json

        expect(response).to have_http_status(:success)
        call.reload
        expect(call.status).to eq('completed')
        expect(call.duration_seconds).to eq(42)
        expect(call.end_reason).to eq('hangup')
        expect(call.ended_at).to eq(Time.zone.parse('2026-08-05T10:05:00Z').iso8601)
      end

      it 'touches the linked message so the dashboard re-renders' do
        original = message.updated_at

        travel_to(2.minutes.from_now) do
          patch "/api/v1/accounts/#{account.id}/pathors/calls/#{call.id}",
                params: { status: 'completed' }, headers: admin.create_new_auth_token, as: :json
        end

        expect(message.reload.updated_at).to be > original
      end

      it 'responds with the display status' do
        patch "/api/v1/accounts/#{account.id}/pathors/calls/#{call.id}",
              params: { status: 'no_answer' }, headers: admin.create_new_auth_token, as: :json

        expect(response.parsed_body['status']).to eq('no-answer')
      end

      it 'accepts the dashed display status on the way in' do
        patch "/api/v1/accounts/#{account.id}/pathors/calls/#{call.id}",
              params: { status: 'in-progress' }, headers: admin.create_new_auth_token, as: :json

        expect(call.reload.status).to eq('in_progress')
      end

      it 'ignores a transition out of a terminal status' do
        call.update!(status: 'completed')

        patch "/api/v1/accounts/#{account.id}/pathors/calls/#{call.id}",
              params: { status: 'in_progress', duration_seconds: 99 }, headers: admin.create_new_auth_token, as: :json

        expect(response).to have_http_status(:success)
        call.reload
        expect(call.status).to eq('completed')
        expect(call.duration_seconds).to be_nil
        expect(response.parsed_body['status']).to eq('completed')
      end

      it 'allows a terminal to terminal correction' do
        call.update!(status: 'completed')

        patch "/api/v1/accounts/#{account.id}/pathors/calls/#{call.id}",
              params: { status: 'failed' }, headers: admin.create_new_auth_token, as: :json

        expect(call.reload.status).to eq('failed')
      end

      it 'returns not found for a call outside the account' do
        other_call = create(:call, :pathors)

        patch "/api/v1/accounts/#{account.id}/pathors/calls/#{other_call.id}",
              params: { status: 'completed' }, headers: admin.create_new_auth_token, as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
