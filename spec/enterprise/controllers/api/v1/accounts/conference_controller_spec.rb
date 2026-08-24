require 'rails_helper'

RSpec.describe Api::V1::Accounts::ConferenceController, type: :request do
  let(:account) { create(:account) }
  let(:voice_channel) { create(:channel_twilio_sms, :with_voice, account: account) }
  let(:voice_inbox) { voice_channel.inbox }
  let(:conversation) { create(:conversation, account: account, inbox: voice_inbox) }
  let(:admin) { create(:user, :administrator, account: account) }
  let(:agent) { create(:user, account: account, role: :agent) }

  let(:webhook_service) { instance_double(Twilio::VoiceWebhookSetupService, perform: true) }
  let(:voice_grant) { instance_double(Twilio::JWT::AccessToken::VoiceGrant) }
  let(:conference_service) do
    instance_double(
      Voice::Provider::Twilio::ConferenceService,
      ensure_conference_sid: 'CF123',
      mark_agent_joined: true,
      end_provider_call: true,
      complete_conference: true
    )
  end

  before do
    allow(Twilio::VoiceWebhookSetupService).to receive(:new).and_return(webhook_service)
    allow(Twilio::JWT::AccessToken::VoiceGrant).to receive(:new).and_return(voice_grant)
    allow(voice_grant).to receive(:outgoing_application_sid=)
    allow(voice_grant).to receive(:outgoing_application_params=)
    allow(voice_grant).to receive(:incoming_allow=)
    allow(Voice::Provider::Twilio::ConferenceService).to receive(:new).and_return(conference_service)
  end

  describe 'GET /conference/token' do
    context 'when unauthenticated' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/inboxes/#{voice_inbox.id}/conference/token"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated agent with inbox access' do
      before { create(:inbox_member, inbox: voice_inbox, user: agent) }

      it 'returns token payload' do
        fake_token = instance_double(Twilio::JWT::AccessToken, to_jwt: 'jwt-token', add_grant: nil)
        allow(Twilio::JWT::AccessToken).to receive(:new).and_return(fake_token)

        get "/api/v1/accounts/#{account.id}/inboxes/#{voice_inbox.id}/conference/token",
            headers: agent.create_new_auth_token

        expect(response).to have_http_status(:ok)
        body = response.parsed_body
        expect(body['token']).to eq('jwt-token')
        expect(body['account_id']).to eq(account.id)
        expect(body['inbox_id']).to eq(voice_inbox.id)
      end
    end
  end

  describe 'POST /conference' do
    context 'when unauthenticated' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/inboxes/#{voice_inbox.id}/conference"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated agent with inbox access' do
      before do
        create(:inbox_member, inbox: voice_inbox, user: agent)
        create(:call, account: account, inbox: voice_inbox, conversation: conversation,
                      contact: conversation.contact, provider_call_id: 'CALL123')
      end

      it 'resolves the Call by call_sid and invokes the conference service' do
        post "/api/v1/accounts/#{account.id}/inboxes/#{voice_inbox.id}/conference",
             headers: agent.create_new_auth_token,
             params: { conversation_id: conversation.display_id, call_sid: 'CALL123' }

        expect(response).to have_http_status(:ok)
        body = response.parsed_body
        expect(body['conference_sid']).to eq('CF123')
        expect(body['id']).to eq(conversation.display_id)
        expect(conference_service).to have_received(:ensure_conference_sid)
        expect(conference_service).to have_received(:mark_agent_joined)
      end

      it 'rejects the request when call_sid is missing' do
        post "/api/v1/accounts/#{account.id}/inboxes/#{voice_inbox.id}/conference",
             headers: agent.create_new_auth_token,
             params: { conversation_id: conversation.display_id }

        expect(response).to have_http_status(:unprocessable_content)
        expect(conference_service).not_to have_received(:ensure_conference_sid)
      end

      it 'does not allow accessing calls from inboxes without access' do
        other_inbox = create(:inbox, account: account)
        other_conversation = create(:conversation, account: account, inbox: other_inbox)
        create(:call, account: account, inbox: other_inbox, conversation: other_conversation,
                      contact: other_conversation.contact, provider_call_id: 'OTHER123')

        post "/api/v1/accounts/#{account.id}/inboxes/#{voice_inbox.id}/conference",
             headers: agent.create_new_auth_token,
             params: { conversation_id: other_conversation.display_id, call_sid: 'OTHER123' }

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'DELETE /conference' do
    context 'when unauthenticated' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/inboxes/#{voice_inbox.id}/conference"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated agent with inbox access' do
      before do
        create(:inbox_member, inbox: voice_inbox, user: agent)
        create(:call, account: account, inbox: voice_inbox, conversation: conversation,
                      contact: conversation.contact, provider_call_id: 'CALL123', direction: :outgoing)
      end

      it 'ends the provider call and marks a pre-pickup outbound hangup as rejected' do
        delete "/api/v1/accounts/#{account.id}/inboxes/#{voice_inbox.id}/conference",
               headers: agent.create_new_auth_token,
               params: { conversation_id: conversation.display_id, call_sid: 'CALL123' }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['id']).to eq(conversation.display_id)
        expect(conference_service).to have_received(:end_provider_call)
        expect(conference_service).to have_received(:complete_conference)
        call = Call.find_by(provider_call_id: 'CALL123')
        expect(call.status).to eq('rejected')
        expect(call.end_reason).to eq('agent_rejected')
      end

      it 'keeps the local call frozen until provider teardown succeeds' do
        allow(conference_service).to receive(:end_provider_call) do
          call = Call.find_by(provider_call_id: 'CALL123')
          expect(call).not_to be_terminal
          expect(call.meta['agent_termination_token']).to be_present
        end

        delete "/api/v1/accounts/#{account.id}/inboxes/#{voice_inbox.id}/conference",
               headers: agent.create_new_auth_token,
               params: { conversation_id: conversation.display_id, call_sid: 'CALL123' }

        expect(response).to have_http_status(:ok)
        call = Call.find_by(provider_call_id: 'CALL123')
        expect(call).to be_terminal
        expect(call.meta['agent_termination_token']).to be_nil
      end

      it 'rejects a concurrent teardown without clearing the existing owner token' do
        call = Call.find_by(provider_call_id: 'CALL123')
        call.update!(meta: call.meta.merge('agent_termination_token' => 'owner-token'))

        delete "/api/v1/accounts/#{account.id}/inboxes/#{voice_inbox.id}/conference",
               headers: agent.create_new_auth_token,
               params: { conversation_id: conversation.display_id, call_sid: 'CALL123' }

        expect(response).to have_http_status(:conflict)
        expect(response.parsed_body['error']).to eq('Call termination is already in progress')
        expect(call.reload.meta['agent_termination_token']).to eq('owner-token')
        expect(conference_service).not_to have_received(:end_provider_call)
        expect(conference_service).not_to have_received(:complete_conference)
      end

      it 'leaves the local call repairable when provider teardown fails' do
        provider_error = StandardError.new('provider teardown failed')
        allow(conference_service).to receive(:end_provider_call).and_raise(provider_error)

        expect do
          delete "/api/v1/accounts/#{account.id}/inboxes/#{voice_inbox.id}/conference",
                 headers: agent.create_new_auth_token,
                 params: { conversation_id: conversation.display_id, call_sid: 'CALL123' }
        end.to raise_error(provider_error)

        call = Call.find_by(provider_call_id: 'CALL123')
        expect(call).not_to be_terminal
        expect(call.meta['agent_termination_token']).to be_nil
        expect(conference_service).not_to have_received(:complete_conference)
      end

      it 'keeps the local call terminal when conference cleanup fails after provider teardown' do
        cleanup_error = StandardError.new('conference cleanup failed')
        allow(conference_service).to receive(:complete_conference).and_raise(cleanup_error)

        expect do
          delete "/api/v1/accounts/#{account.id}/inboxes/#{voice_inbox.id}/conference",
                 headers: agent.create_new_auth_token,
                 params: { conversation_id: conversation.display_id, call_sid: 'CALL123' }
        end.to raise_error(cleanup_error)

        call = Call.find_by(provider_call_id: 'CALL123')
        expect(call).to be_terminal
        expect(call.status).to eq('rejected')
        expect(call.end_reason).to eq('agent_rejected')
        expect(call.meta['agent_termination_token']).to be_nil
      end

      it 'marks an incoming rejection as rejected after provider teardown' do
        call = Call.find_by(provider_call_id: 'CALL123')
        call.update!(direction: :incoming)

        delete "/api/v1/accounts/#{account.id}/inboxes/#{voice_inbox.id}/conference",
               headers: agent.create_new_auth_token,
               params: { conversation_id: conversation.display_id, call_sid: 'CALL123' }

        expect(response).to have_http_status(:ok)
        expect(conference_service).to have_received(:end_provider_call)
        call.reload
        expect(call.status).to eq('rejected')
        expect(call.end_reason).to eq('agent_rejected')
      end

      it 'marks an in-progress call as completed after provider teardown' do
        call = Call.find_by(provider_call_id: 'CALL123')
        call.update!(status: 'in_progress', accepted_by_agent_id: agent.id, started_at: 30.seconds.ago)

        delete "/api/v1/accounts/#{account.id}/inboxes/#{voice_inbox.id}/conference",
               headers: agent.create_new_auth_token,
               params: { conversation_id: conversation.display_id, call_sid: 'CALL123' }

        expect(response).to have_http_status(:ok)
        expect(conference_service).to have_received(:end_provider_call)
        call.reload
        expect(call.status).to eq('completed')
        expect(call.end_reason).to eq('agent_hangup')
        expect(call.terminal?).to be true
        expect(call.duration_seconds).to be >= 30
        expect(call.ended_at).to be_present
      end

      it 'marks a claimed-but-not-yet-connected outbound call as no_answer' do
        call = Call.find_by(provider_call_id: 'CALL123')
        call.update!(accepted_by_agent_id: agent.id)

        delete "/api/v1/accounts/#{account.id}/inboxes/#{voice_inbox.id}/conference",
               headers: agent.create_new_auth_token,
               params: { conversation_id: conversation.display_id, call_sid: 'CALL123' }

        expect(response).to have_http_status(:ok)
        expect(conference_service).to have_received(:end_provider_call)
        call.reload
        expect(call.status).to eq('no_answer')
        expect(call.end_reason).to eq('agent_hangup')
        expect(call.terminal?).to be true
      end

      it 'does not allow ending conferences for calls from inboxes without access' do
        other_inbox = create(:inbox, account: account)
        other_conversation = create(:conversation, account: account, inbox: other_inbox)
        create(:call, account: account, inbox: other_inbox, conversation: other_conversation,
                      contact: other_conversation.contact, provider_call_id: 'OTHER123')

        delete "/api/v1/accounts/#{account.id}/inboxes/#{voice_inbox.id}/conference",
               headers: agent.create_new_auth_token,
               params: { conversation_id: other_conversation.display_id, call_sid: 'OTHER123' }

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
