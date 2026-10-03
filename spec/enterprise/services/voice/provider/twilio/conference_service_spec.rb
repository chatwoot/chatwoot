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
      conversation.update!(ai_assignee: agent_bot)

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

  describe '#terminate_call' do
    let(:call_context) { instance_double(Twilio::REST::Api::V2010::AccountContext::CallContext, update: true) }

    before { allow(twilio_client).to receive(:calls).and_return(call_context) }

    it 'hangs up the provider call leg with status completed' do
      service.terminate_call

      expect(twilio_client).to have_received(:calls).with(call.provider_call_id).once
      expect(call_context).to have_received(:update).with(status: 'completed').once
    end

    it 'also hangs up the parent call leg when it differs from the provider call' do
      call.update!(parent_call_sid: 'CA_parent')

      service.terminate_call

      expect(twilio_client).to have_received(:calls).with(call.provider_call_id)
      expect(twilio_client).to have_received(:calls).with('CA_parent')
      expect(call_context).to have_received(:update).with(status: 'completed').twice
    end

    it 'hangs up a leg only once when the parent call is the provider call' do
      call.update!(parent_call_sid: call.provider_call_id)

      service.terminate_call

      expect(call_context).to have_received(:update).with(status: 'completed').once
    end
  end
end
