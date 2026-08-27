require 'rails_helper'

describe Voice::Provider::Twilio::ConferenceService do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_twilio_sms, :with_voice, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: channel.inbox) }
  let(:call) do
    create(
      :call,
      account: account,
      inbox: channel.inbox,
      conversation: conversation,
      contact: conversation.contact
    )
  end
  let(:twilio_client) { instance_double(Twilio::REST::Client) }
  let(:service) { described_class.new(call: call) }
  let(:webhook_service) { instance_double(Twilio::VoiceWebhookSetupService, perform: true) }

  before do
    allow(Twilio::VoiceWebhookSetupService).to receive(:new).and_return(webhook_service)
    allow(Twilio::REST::Client).to receive(:new).and_return(twilio_client)
  end

  describe '#ensure_conference_sid' do
    it 'returns existing sid if present on the Call' do
      call.update!(conference_sid: 'CF_EXISTING')

      expect(service.ensure_conference_sid).to eq('CF_EXISTING')
    end

    it 'sets and returns generated sid when missing' do
      expect(service.ensure_conference_sid).to eq("conf_account_#{account.id}_call_#{call.id}")
      expect(call.reload.conference_sid).to eq("conf_account_#{account.id}_call_#{call.id}")
    end
  end

  describe '#mark_agent_joined' do
    it 'sets accepted_by_agent on the Call' do
      agent = create(:user, account: account)

      service.mark_agent_joined(user: agent)

      expect(call.reload.accepted_by_agent_id).to eq(agent.id)
    end

    it 'keeps an existing AgentBot conversation owner' do
      agent = create(:user, account: account)
      agent_bot = create(:agent_bot, account: account)
      conversation.update!(assignee_agent_bot: agent_bot)

      service.mark_agent_joined(user: agent)

      expect(conversation.reload.assigned_entity).to eq(agent_bot)
    end
  end

  describe '#end_conference' do
    it 'completes in-progress conferences matching the call conference_sid' do
      call.update!(conference_sid: 'CF123_FRIENDLY')
      conferences_proxy = instance_double(Twilio::REST::Api::V2010::AccountContext::ConferenceList)
      conf_instance = instance_double(Twilio::REST::Api::V2010::AccountContext::ConferenceInstance, sid: 'CF123')
      conf_context = instance_double(Twilio::REST::Api::V2010::AccountContext::ConferenceInstance)

      allow(twilio_client).to receive(:conferences).with(no_args).and_return(conferences_proxy)
      allow(conferences_proxy).to receive(:list).with(friendly_name: 'CF123_FRIENDLY', status: 'in-progress').and_return([conf_instance])
      allow(twilio_client).to receive(:conferences).with('CF123').and_return(conf_context)
      allow(conf_context).to receive(:update).with(status: 'completed')

      service.end_conference

      expect(conf_context).to have_received(:update).with(status: 'completed')
    end

    it 'no-ops when call has no conference_sid' do
      allow(twilio_client).to receive(:conferences)
      service.end_conference
      expect(twilio_client).not_to have_received(:conferences)
    end
  end

  describe 'recording controls' do
    let(:recording_context) { instance_double(Twilio::REST::Api::V2010::AccountContext::ConferenceContext::RecordingContext, update: true) }
    let(:conf_context) { instance_double(Twilio::REST::Api::V2010::AccountContext::ConferenceContext, recordings: recording_context) }
    let(:call_recordings) { instance_double(Twilio::REST::Api::V2010::AccountContext::CallContext::RecordingList, create: true) }
    let(:call_recording_context) { instance_double(Twilio::REST::Api::V2010::AccountContext::CallContext::RecordingContext, update: true) }
    let(:call_context) { instance_double(Twilio::REST::Api::V2010::AccountContext::CallContext) }

    before do
      allow(twilio_client).to receive(:calls).with(call.provider_call_id).and_return(call_context)
      allow(call_context).to receive(:recordings).with(no_args).and_return(call_recordings)
      allow(call_context).to receive(:recordings).with('Twilio.CURRENT').and_return(call_recording_context)
    end

    describe '#start_recording' do
      it 'starts a recording on the contact leg with our status callback and marks the call as recording' do
        service.start_recording

        expect(call_recordings).to have_received(:create).with(
          recording_status_callback: channel.voice_recording_status_webhook_url,
          recording_status_callback_event: ['completed'],
          recording_status_callback_method: 'POST'
        )
        expect(call.reload.recording_started).to be true
      end
    end

    describe '#stop_recording' do
      it 'stops the conference recording using the persisted Twilio conference sid and the contact leg recording' do
        call.update!(twilio_conference_sid: 'CF_live', recording_started: true)
        allow(twilio_client).to receive(:conferences).with('CF_live').and_return(conf_context)

        service.stop_recording

        expect(conf_context).to have_received(:recordings).with('Twilio.CURRENT')
        expect(recording_context).to have_received(:update).with(status: 'stopped')
        expect(call_recording_context).to have_received(:update).with(status: 'stopped')
        expect(call.reload.recording_started).to be false
      end

      it 'resolves the conference by friendly name when the Twilio sid is not persisted yet' do
        call.update!(conference_sid: 'CF123_FRIENDLY')
        conferences_proxy = instance_double(Twilio::REST::Api::V2010::AccountContext::ConferenceList)
        conf_instance = instance_double(Twilio::REST::Api::V2010::AccountContext::ConferenceInstance, sid: 'CF_found')
        allow(twilio_client).to receive(:conferences).with(no_args).and_return(conferences_proxy)
        allow(conferences_proxy).to receive(:list).with(friendly_name: 'CF123_FRIENDLY', status: 'in-progress').and_return([conf_instance])
        allow(twilio_client).to receive(:conferences).with('CF_found').and_return(conf_context)

        service.stop_recording

        expect(recording_context).to have_received(:update).with(status: 'stopped')
      end

      it 'ignores a 404 when nothing is being recorded' do
        call.update!(twilio_conference_sid: 'CF_live')
        allow(twilio_client).to receive(:conferences).with('CF_live').and_return(conf_context)
        not_found = Twilio::REST::RestError.new('not found', OpenStruct.new(status_code: 404, body: {}))
        allow(recording_context).to receive(:update).and_raise(not_found)
        allow(call_recording_context).to receive(:update).and_raise(not_found)

        expect { service.stop_recording }.not_to raise_error
        expect(call.reload.recording_started).to be false
      end
    end
  end
end
