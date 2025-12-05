require 'rails_helper'

describe Voice::Conference::EndService do
  let(:account) { create(:account) }
  let(:voice_channel) { create(:channel_voice, account: account) }
  let(:inbox) { voice_channel.inbox }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:webhook_service) { instance_double(Twilio::VoiceWebhookSetupService, perform: true) }
  let(:conferences_proxy) do
    instance_double(Twilio::REST::Api::V2010::AccountContext::ConferenceList)
  end
  let(:conference_context) do
    instance_double(Twilio::REST::Api::V2010::AccountContext::ConferenceInstance)
  end
  let(:conf_double) do
    instance_double(Twilio::REST::Api::V2010::AccountContext::ConferenceInstance, sid: 'CF123')
  end

  before do
    allow(Twilio::VoiceWebhookSetupService).to receive(:new).and_return(webhook_service)
  end

  it 'completes in-progress conferences for the conversation' do
    allow(conferences_proxy).to receive(:list)
      .with(hash_including(friendly_name: Voice::Conference::Name.for(conversation), status: 'in-progress'))
      .and_return([conf_double])

    allow(conference_context).to receive(:update).with(status: 'completed')

    client_double = instance_double(Twilio::REST::Client)
    allow(client_double).to receive(:conferences).with(no_args).and_return(conferences_proxy)
    allow(client_double).to receive(:conferences).with('CF123').and_return(conference_context)

    allow(Twilio::REST::Client).to receive(:new)
      .with(voice_channel.provider_config_hash['account_sid'], voice_channel.provider_config_hash['auth_token'])
      .and_return(client_double)

    described_class.new(conversation: conversation).perform

    expect(conference_context).to have_received(:update).with(status: 'completed')
  end
end
