require 'rails_helper'

describe Voice::Provider::Twilio::ConferenceService do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_voice, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: channel.inbox) }
  let(:twilio_client) { instance_double(Twilio::REST::Client) }
  let(:service) { described_class.new(conversation: conversation, twilio_client: twilio_client) }
  let(:webhook_service) { instance_double(Twilio::VoiceWebhookSetupService, perform: true) }

  before do
    allow(Twilio::VoiceWebhookSetupService).to receive(:new).and_return(webhook_service)
  end

  describe '#ensure_conference_sid' do
    it 'returns existing sid if present' do
      conversation.update!(additional_attributes: { 'conference_sid' => 'CF_EXISTING' })

      expect(service.ensure_conference_sid).to eq('CF_EXISTING')
    end

    it 'sets and returns generated sid when missing' do
      allow(Voice::Conference::Name).to receive(:for).and_return('CF_GEN')

      sid = service.ensure_conference_sid

      expect(sid).to eq('CF_GEN')
      expect(conversation.reload.additional_attributes['conference_sid']).to eq('CF_GEN')
    end
  end

  describe '#mark_agent_joined' do
    it 'stores agent join metadata' do
      agent = create(:user, account: account)

      service.mark_agent_joined(user: agent)

      attrs = conversation.reload.additional_attributes
      expect(attrs['agent_joined']).to be true
      expect(attrs['joined_by']['id']).to eq(agent.id)
    end
  end

  describe '#end_conference' do
    it 'completes in-progress conferences' do
      conferences_proxy = instance_double(Twilio::REST::Api::V2010::AccountContext::ConferenceList)
      conf_instance = instance_double(Twilio::REST::Api::V2010::AccountContext::ConferenceInstance, sid: 'CF123')
      conf_context = instance_double(Twilio::REST::Api::V2010::AccountContext::ConferenceInstance)

      allow(twilio_client).to receive(:conferences).with(no_args).and_return(conferences_proxy)
      allow(conferences_proxy).to receive(:list).and_return([conf_instance])
      allow(twilio_client).to receive(:conferences).with('CF123').and_return(conf_context)
      allow(conf_context).to receive(:update).with(status: 'completed')

      service.end_conference

      expect(conf_context).to have_received(:update).with(status: 'completed')
    end
  end
end
