require 'rails_helper'

RSpec.describe Api::V1::Accounts::ConferenceController, type: :request do
  let(:account) { create(:account) }
  let(:voice_channel) { create(:channel_voice, account: account) }
  let(:voice_inbox) { voice_channel.inbox }
  let(:conversation) { create(:conversation, account: account, inbox: voice_inbox, identifier: nil) }
  let(:admin) { create(:user, :administrator, account: account) }
  let(:agent) { create(:user, account: account, role: :agent) }

  let(:webhook_service) { instance_double(Twilio::VoiceWebhookSetupService, perform: true) }
  let(:voice_grant) { instance_double(Twilio::JWT::AccessToken::VoiceGrant) }
  let(:conference_service) do
    instance_double(
      Voice::Provider::Twilio::ConferenceService,
      ensure_conference_sid: 'CF123',
      mark_agent_joined: true,
      end_conference: true
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
      before { create(:inbox_member, inbox: voice_inbox, user: agent) }

      it 'creates conference and sets identifier' do
        post "/api/v1/accounts/#{account.id}/inboxes/#{voice_inbox.id}/conference",
             headers: agent.create_new_auth_token,
             params: { conversation_id: conversation.display_id, call_sid: 'CALL123' }

        expect(response).to have_http_status(:ok)
        body = response.parsed_body
        expect(body['conference_sid']).to be_present
        conversation.reload
        expect(conversation.identifier).to eq('CALL123')
        expect(conference_service).to have_received(:ensure_conference_sid)
        expect(conference_service).to have_received(:mark_agent_joined)
      end

      it 'does not allow accessing conversations from inboxes without access' do
        other_inbox = create(:inbox, account: account)
        other_conversation = create(:conversation, account: account, inbox: other_inbox, identifier: nil)

        post "/api/v1/accounts/#{account.id}/inboxes/#{voice_inbox.id}/conference",
             headers: agent.create_new_auth_token,
             params: { conversation_id: other_conversation.display_id, call_sid: 'CALL123' }

        expect(response).to have_http_status(:not_found)
        other_conversation.reload
        expect(other_conversation.identifier).to be_nil
      end

      it 'returns conflict when call_sid missing' do
        post "/api/v1/accounts/#{account.id}/inboxes/#{voice_inbox.id}/conference",
             headers: agent.create_new_auth_token,
             params: { conversation_id: conversation.display_id }

        expect(response).to have_http_status(:unprocessable_content)
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
      before { create(:inbox_member, inbox: voice_inbox, user: agent) }

      it 'ends conference and returns success' do
        delete "/api/v1/accounts/#{account.id}/inboxes/#{voice_inbox.id}/conference",
               headers: agent.create_new_auth_token,
               params: { conversation_id: conversation.display_id }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['id']).to eq(conversation.display_id)
        expect(conference_service).to have_received(:end_conference)
      end

      it 'does not allow ending conferences for conversations from inboxes without access' do
        other_inbox = create(:inbox, account: account)
        other_conversation = create(:conversation, account: account, inbox: other_inbox, identifier: nil)

        delete "/api/v1/accounts/#{account.id}/inboxes/#{voice_inbox.id}/conference",
               headers: agent.create_new_auth_token,
               params: { conversation_id: other_conversation.display_id }

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
