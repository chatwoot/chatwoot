require 'rails_helper'

describe Voice::Provider::Twilio::ConferenceService do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_twilio_sms, :with_voice, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: channel.inbox) }
  let(:call) do
    create(:call, account: account, inbox: channel.inbox, conversation: conversation, contact: conversation.contact)
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
    it 'cancels a provider leg that is still ringing and completes the active conference' do
      call.update!(provider_call_id: 'CALL123', conference_sid: 'CF123_FRIENDLY')
      call_context = instance_double(Twilio::REST::Api::V2010::AccountContext::CallContext)
      call_instance = instance_double(Twilio::REST::Api::V2010::AccountContext::CallInstance, status: 'ringing')
      conferences_proxy = instance_double(Twilio::REST::Api::V2010::AccountContext::ConferenceList)
      conf_instance = instance_double(Twilio::REST::Api::V2010::AccountContext::ConferenceInstance, sid: 'CF123')
      conf_context = instance_double(Twilio::REST::Api::V2010::AccountContext::ConferenceInstance)

      allow(twilio_client).to receive(:calls).with('CALL123').and_return(call_context)
      allow(call_context).to receive(:fetch).and_return(call_instance)
      allow(call_context).to receive(:update).with(status: 'canceled')
      allow(twilio_client).to receive(:conferences).with(no_args).and_return(conferences_proxy)
      allow(conferences_proxy).to receive(:list).with(friendly_name: 'CF123_FRIENDLY', status: 'in-progress').and_return([conf_instance])
      allow(twilio_client).to receive(:conferences).with('CF123').and_return(conf_context)
      allow(conf_context).to receive(:update).with(status: 'completed')

      service.end_conference

      expect(call_context).to have_received(:update).with(status: 'canceled')
      expect(conf_context).to have_received(:update).with(status: 'completed')
    end

    it 'completes a provider leg that is already in progress' do
      call.update!(provider_call_id: 'CALL123')
      call_context = instance_double(Twilio::REST::Api::V2010::AccountContext::CallContext)
      call_instance = instance_double(Twilio::REST::Api::V2010::AccountContext::CallInstance, status: 'in-progress')

      allow(twilio_client).to receive(:calls).with('CALL123').and_return(call_context)
      allow(call_context).to receive(:fetch).and_return(call_instance)
      allow(call_context).to receive(:update).with(status: 'completed')

      service.end_conference

      expect(call_context).to have_received(:update).with(status: 'completed')
    end

    it 'retries as completed when a ringing leg answers between fetch and update' do
      call.update!(provider_call_id: 'CALL123')
      call_context = instance_double(Twilio::REST::Api::V2010::AccountContext::CallContext)
      ringing_instance = instance_double(Twilio::REST::Api::V2010::AccountContext::CallInstance, status: 'ringing')
      in_progress_instance = instance_double(Twilio::REST::Api::V2010::AccountContext::CallInstance, status: 'in-progress')
      transition_error = Twilio::REST::RestError.allocate

      allow(twilio_client).to receive(:calls).with('CALL123').and_return(call_context)
      allow(call_context).to receive(:fetch).and_return(ringing_instance, in_progress_instance)
      allow(call_context).to receive(:update).with(status: 'canceled').and_raise(transition_error)
      allow(call_context).to receive(:update).with(status: 'completed')

      service.end_conference

      expect(call_context).to have_received(:fetch).twice
      expect(call_context).to have_received(:update).with(status: 'canceled')
      expect(call_context).to have_received(:update).with(status: 'completed')
    end

    it 'reconciles an ambiguous Twilio transport error after provider termination' do
      call.update!(provider_call_id: 'CALL123')
      call_context = instance_double(Twilio::REST::Api::V2010::AccountContext::CallContext)
      ringing_instance = instance_double(Twilio::REST::Api::V2010::AccountContext::CallInstance, status: 'ringing')
      completed_instance = instance_double(Twilio::REST::Api::V2010::AccountContext::CallInstance, status: 'completed')
      transport_error = Twilio::REST::TwilioError.new('connection reset after update')

      allow(twilio_client).to receive(:calls).with('CALL123').and_return(call_context)
      allow(call_context).to receive(:fetch).and_return(ringing_instance, completed_instance)
      allow(call_context).to receive(:update).with(status: 'canceled').and_raise(transport_error)

      expect { service.end_conference }.not_to raise_error
      expect(call_context).to have_received(:fetch).twice
      expect(call_context).to have_received(:update).with(status: 'canceled').once
    end

    it 'uses provider state even when the local call is in progress but the customer is still ringing' do
      call.update!(provider_call_id: 'CALL123', status: 'in_progress')
      call_context = instance_double(Twilio::REST::Api::V2010::AccountContext::CallContext)
      call_instance = instance_double(Twilio::REST::Api::V2010::AccountContext::CallInstance, status: 'ringing')

      allow(twilio_client).to receive(:calls).with('CALL123').and_return(call_context)
      allow(call_context).to receive(:fetch).and_return(call_instance)
      allow(call_context).to receive(:update).with(status: 'canceled')

      service.end_conference

      expect(call_context).to have_received(:update).with(status: 'canceled')
    end

    it 'does not update an already-terminal provider leg' do
      call.update!(provider_call_id: 'CALL123')
      call_context = instance_double(Twilio::REST::Api::V2010::AccountContext::CallContext)
      call_instance = instance_double(Twilio::REST::Api::V2010::AccountContext::CallInstance, status: 'completed')

      allow(twilio_client).to receive(:calls).with('CALL123').and_return(call_context)
      allow(call_context).to receive(:fetch).and_return(call_instance)
      allow(call_context).to receive(:update)

      service.end_conference

      expect(call_context).not_to have_received(:update)
    end

    it 'propagates provider teardown failures' do
      call.update!(provider_call_id: 'CALL123')
      call_context = instance_double(Twilio::REST::Api::V2010::AccountContext::CallContext)
      provider_error = StandardError.new('provider teardown failed')

      allow(twilio_client).to receive(:calls).with('CALL123').and_return(call_context)
      allow(call_context).to receive(:fetch).and_raise(provider_error)

      expect { service.end_conference }.to raise_error(provider_error)
    end
  end
end
