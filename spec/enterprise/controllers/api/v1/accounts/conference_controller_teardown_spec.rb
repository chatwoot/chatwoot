require 'rails_helper'

RSpec.describe Api::V1::Accounts::ConferenceController, type: :request do
  let(:account) { create(:account) }
  let(:voice_channel) { create(:channel_twilio_sms, :with_voice, account: account) }
  let(:voice_inbox) { voice_channel.inbox }
  let(:conversation) { create(:conversation, account: account, inbox: voice_inbox) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:webhook_service) { instance_double(Twilio::VoiceWebhookSetupService, perform: true) }
  let(:conference_service) do
    instance_double(
      Voice::Provider::Twilio::ConferenceService,
      end_provider_call: true,
      complete_conference: true
    )
  end

  before do
    allow(Twilio::VoiceWebhookSetupService).to receive(:new).and_return(webhook_service)
    allow(Voice::Provider::Twilio::ConferenceService).to receive(:new).and_return(conference_service)
    create(:inbox_member, inbox: voice_inbox, user: agent)
    create(
      :call,
      account: account,
      inbox: voice_inbox,
      conversation: conversation,
      contact: conversation.contact,
      provider_call_id: 'CALL123',
      direction: :outgoing,
      status: 'ringing'
    )
  end

  it 'preserves the pre-answer rejection when a late progress callback races with teardown' do
    allow(conference_service).to receive(:end_provider_call) do
      call = Call.find_by!(provider_call_id: 'CALL123')
      expect(call.meta['agent_termination_token']).to be_present
      expect(call.meta['agent_termination_started_at']).to be_present

      Voice::CallStatus::Manager.new(call: call).process_status_update('in_progress')
      expect(call.reload.status).to eq('ringing')
    end

    delete "/api/v1/accounts/#{account.id}/inboxes/#{voice_inbox.id}/conference",
           headers: agent.create_new_auth_token,
           params: { conversation_id: conversation.display_id, call_sid: 'CALL123' }

    expect(response).to have_http_status(:ok)
    call = Call.find_by!(provider_call_id: 'CALL123')
    expect(call.status).to eq('rejected')
    expect(call.end_reason).to eq('agent_rejected')
    expect(call.accepted_by_agent_id).to eq(agent.id)
    expect(call.meta['agent_termination_token']).to be_nil
    expect(call.meta['agent_termination_started_at']).to be_nil
  end

  it 'recovers an abandoned teardown guard and allows a new termination attempt' do
    call = Call.find_by!(provider_call_id: 'CALL123')
    call.update!(
      meta: call.meta.merge(
        'agent_termination_token' => 'abandoned-token',
        'agent_termination_started_at' => 3.minutes.ago.to_i
      )
    )

    delete "/api/v1/accounts/#{account.id}/inboxes/#{voice_inbox.id}/conference",
           headers: agent.create_new_auth_token,
           params: { conversation_id: conversation.display_id, call_sid: 'CALL123' }

    expect(response).to have_http_status(:ok)
    expect(conference_service).to have_received(:end_provider_call)
    expect(call.reload.status).to eq('rejected')
    expect(call.meta['agent_termination_token']).to be_nil
    expect(call.meta['agent_termination_started_at']).to be_nil
  end

  it 'binds failed teardown cleanup to the initiating tab agent leg' do
    allow(conference_service).to receive(:end_provider_call).and_raise(StandardError, 'provider teardown failed')

    delete "/api/v1/accounts/#{account.id}/inboxes/#{voice_inbox.id}/conference",
           headers: agent.create_new_auth_token,
           params: {
             conversation_id: conversation.display_id,
             call_sid: 'CALL123',
             agent_call_sid: 'CA_OLD_TAB'
           }

    expect(response).to have_http_status(:internal_server_error)
    call = Call.find_by!(provider_call_id: 'CALL123')
    expect(call).not_to be_terminal
    expect(call.meta['agent_termination_token']).to be_nil
    expect(call.meta['agent_disconnect_suppress_call_sid']).to eq('CA_OLD_TAB')
  end
end
