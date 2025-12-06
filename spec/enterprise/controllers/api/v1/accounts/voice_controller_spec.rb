require 'rails_helper'

RSpec.describe 'Voice Conference API', type: :request do
  let(:account) { create(:account) }
  let(:voice_channel) { create(:channel_voice, account: account) }
  let(:voice_inbox) { voice_channel.inbox }
  let(:conversation) { create(:conversation, account: account, inbox: voice_inbox, identifier: nil) }
  let(:admin) { create(:user, :administrator, account: account) }
  let(:agent) { create(:user, account: account, role: :agent) }

  let(:webhook_service) { instance_double(Twilio::VoiceWebhookSetupService, perform: true) }
  let(:voice_grant) { instance_double(Twilio::JWT::AccessToken::VoiceGrant) }

  before do
    allow(Twilio::VoiceWebhookSetupService).to receive(:new).and_return(webhook_service)
    allow(Twilio::JWT::AccessToken::VoiceGrant).to receive(:new).and_return(voice_grant)
    allow(voice_grant).to receive(:outgoing_application_sid=)
    allow(voice_grant).to receive(:outgoing_application_params=)
    allow(voice_grant).to receive(:incoming_allow=)
  end

  describe 'GET /conference_token' do
    let(:url) { "/api/v1/accounts/#{account.id}/inboxes/#{voice_inbox.id}/conference_token" }

    context 'when unauthenticated' do
      it 'returns unauthorized' do
        get url
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated agent with inbox access' do
      before { create(:inbox_member, inbox: voice_inbox, user: agent) }

      it 'returns token payload' do
        fake_token = instance_double(Twilio::JWT::AccessToken, to_jwt: 'jwt-token', add_grant: nil)
        allow(Twilio::JWT::AccessToken).to receive(:new).and_return(fake_token)

        get url, headers: agent.create_new_auth_token

        expect(response).to have_http_status(:ok)
        body = response.parsed_body
        expect(body['token']).to eq('jwt-token')
        expect(body['account_id']).to eq(account.id)
        expect(body['inbox_id']).to eq(voice_inbox.id)
      end
    end
  end

  describe 'POST /conference' do
    let(:url) { "/api/v1/accounts/#{account.id}/inboxes/#{voice_inbox.id}/conference" }

    context 'when unauthenticated' do
      it 'returns unauthorized' do
        post url
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated agent with inbox access' do
      before { create(:inbox_member, inbox: voice_inbox, user: agent) }

      it 'creates conference and sets identifier' do
        post url,
             headers: agent.create_new_auth_token,
             params: { conversation_id: conversation.display_id, call_sid: 'CALL123' }

        expect(response).to have_http_status(:ok)
        body = response.parsed_body
        expect(body['conference_sid']).to be_present
        conversation.reload
        expect(conversation.identifier).to eq('CALL123')
        expect(conversation.additional_attributes['conference_sid']).to eq(body['conference_sid'])
        expect(conversation.additional_attributes['agent_joined']).to be true
      end

      it 'returns conflict when call_sid missing' do
        post url,
             headers: agent.create_new_auth_token,
             params: { conversation_id: conversation.display_id }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'DELETE /conference' do
    let(:url) { "/api/v1/accounts/#{account.id}/inboxes/#{voice_inbox.id}/conference" }

    context 'when unauthenticated' do
      it 'returns unauthorized' do
        delete url
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated agent with inbox access' do
      before { create(:inbox_member, inbox: voice_inbox, user: agent) }

      it 'ends conference and returns success' do
        end_service = instance_double(Voice::Conference::EndService, perform: true)
        allow(Voice::Conference::EndService).to receive(:new).and_return(end_service)

        delete url,
               headers: agent.create_new_auth_token,
               params: { conversation_id: conversation.display_id }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['id']).to eq(conversation.display_id)
      end
    end
  end
end
