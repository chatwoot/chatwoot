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
      expect(call.meta).to include(
        'agent_termination_token' => be_present,
        'agent_termination_started_at' => be_present
      )

      Voice::CallStatus::Manager.new(call: call).process_status_update('in_progress')
      expect(call.reload.status).to eq('ringing')
    end

    delete "/api/v1/accounts/#{account.id}/inboxes/#{voice_inbox.id}/conference",
           headers: agent.create_new_auth_token,
           params: { conversation_id: conversation.display_id, call_sid: 'CALL123' }

    expect(response).to have_http_status(:ok)
    call = Call.find_by!(provider_call_id: 'CALL123')
    expect(call.attributes.symbolize_keys).to include(
      status: 'rejected',
      end_reason: 'agent_rejected',
      accepted_by_agent_id: agent.id
    )
    expect(call.meta).not_to include('agent_termination_token', 'agent_termination_started_at')
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

  it 'does not suppress a future disconnect when failed teardown keeps the agent participant connected' do
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
    expect(call.meta['agent_disconnect_suppress_call_sid']).to be_blank
  end

  it 'replays a provider progress callback when provider teardown fails' do
    timestamp = Time.zone.now.to_i
    allow(conference_service).to receive(:end_provider_call) do
      call = Call.find_by!(provider_call_id: 'CALL123')
      Voice::CallStatus::Manager.new(call: call).process_status_update('in_progress', timestamp: timestamp)
      raise StandardError, 'provider teardown failed'
    end

    delete "/api/v1/accounts/#{account.id}/inboxes/#{voice_inbox.id}/conference",
           headers: agent.create_new_auth_token,
           params: { conversation_id: conversation.display_id, call_sid: 'CALL123' }

    expect(response).to have_http_status(:internal_server_error)
    call = Call.find_by!(provider_call_id: 'CALL123')
    expect(call.status).to eq('in_progress')
    expect(call.started_at.to_i).to eq(timestamp)
    expect(call.meta['agent_termination_token']).to be_nil
    expect(call.meta['agent_termination_pending_status']).to be_nil
  end

  it 'replays an agent join when provider teardown fails' do
    allow(conference_service).to receive(:end_provider_call) do
      call = Call.find_by!(provider_call_id: 'CALL123')
      Voice::Conference::Manager.new(
        call: call,
        event: 'join',
        participant_label: "agent-#{agent.id}-account-#{account.id}",
        participant_call_sid: 'CA_AGENT_1'
      ).process
      expect(call.reload.status).to eq('ringing')
      raise StandardError, 'provider teardown failed'
    end

    delete "/api/v1/accounts/#{account.id}/inboxes/#{voice_inbox.id}/conference",
           headers: agent.create_new_auth_token,
           params: { conversation_id: conversation.display_id, call_sid: 'CALL123' }

    expect(response).to have_http_status(:internal_server_error)
    call = Call.find_by!(provider_call_id: 'CALL123')
    expect(call.status).to eq('in_progress')
    expect(call.accepted_by_agent_id).to eq(agent.id)
    expect(call.accepted_broadcast_at).to be_present
    expect(call.meta['agent_termination_token']).to be_nil
    expect(call.meta['agent_termination_pending_join']).to be_nil
  end

  it 'replays a deferred terminal callback when local finalization fails' do
    allow(conference_service).to receive(:end_provider_call) do
      call = Call.find_by!(provider_call_id: 'CALL123')
      Voice::CallTerminationGuard.persist_pending_status!(
        call,
        status: 'completed',
        duration: 18,
        timestamp: Time.zone.now.to_i
      )
    end
    allow(Voice::CallStatus::Manager).to receive(:new).and_wrap_original do |original, *args, **kwargs|
      manager = original.call(*args, **kwargs)
      allow(manager).to receive(:process_status_update).and_wrap_original do |method, status, **status_kwargs|
        if status == 'rejected' && status_kwargs[:allow_during_termination]
          raise StandardError, 'local finalization failed'
        end

        method.call(status, **status_kwargs)
      end
      manager
    end

    delete "/api/v1/accounts/#{account.id}/inboxes/#{voice_inbox.id}/conference",
           headers: agent.create_new_auth_token,
           params: { conversation_id: conversation.display_id, call_sid: 'CALL123' }

    expect(response).to have_http_status(:internal_server_error)
    call = Call.find_by!(provider_call_id: 'CALL123')
    expect(call.status).to eq('completed')
    expect(call.duration_seconds).to eq(18)
    expect(call.meta['agent_termination_token']).to be_nil
    expect(call.meta['agent_termination_pending_status']).to be_nil
  end

  it 'does not clear deferred state created by a newer teardown while replaying' do
    allow(conference_service).to receive(:end_provider_call) do
      call = Call.find_by!(provider_call_id: 'CALL123')
      Voice::CallTerminationGuard.persist_pending_status!(
        call,
        status: 'in_progress',
        duration: nil,
        timestamp: Time.zone.now.to_i
      )
      raise StandardError, 'provider teardown failed'
    end

    new_owner_created = false
    allow(Voice::CallStatus::Manager).to receive(:new).and_wrap_original do |original, *args, **kwargs|
      manager = original.call(*args, **kwargs)
      call = kwargs[:call]
      allow(manager).to receive(:process_status_update).and_wrap_original do |method, status, **status_kwargs|
        should_create_new_owner = !new_owner_created && !Voice::CallTerminationGuard.active?(call)
        if should_create_new_owner
          call.with_lock do
            call.update!(meta: Voice::CallTerminationGuard.claim_meta(call, token: 'new-owner'))
          end
          Voice::CallTerminationGuard.persist_pending_join!(
            call,
            participant_label: "agent-#{agent.id}-account-#{account.id}",
            participant_call_sid: 'CA_NEW_OWNER',
            timestamp: Time.zone.now.to_i
          )
          new_owner_created = true
        end
        method.call(status, **status_kwargs)
      end
      manager
    end

    delete "/api/v1/accounts/#{account.id}/inboxes/#{voice_inbox.id}/conference",
           headers: agent.create_new_auth_token,
           params: { conversation_id: conversation.display_id, call_sid: 'CALL123' }

    expect(response).to have_http_status(:internal_server_error)
    call = Call.find_by!(provider_call_id: 'CALL123')
    expect(call.meta['agent_termination_token']).to eq('new-owner')
    expect(call.meta.dig('agent_termination_pending_join', 'participant_call_sid')).to eq('CA_NEW_OWNER')
  end
end
