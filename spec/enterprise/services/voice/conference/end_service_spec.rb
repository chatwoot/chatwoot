require 'rails_helper'

describe Voice::Conference::EndService do
  before { allow_any_instance_of(Channel::Voice).to receive(:provision_twilio_on_create).and_return(true) }

  let(:account) { create(:account) }
  let(:voice_channel) { create(:channel_voice, account: account) }
  let(:inbox) { voice_channel.inbox }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }

  it 'completes in-progress conferences for the conversation' do
    conf_double = double('conference', sid: 'CF123')
    conferences_proxy = double('conferences_proxy')
    allow(conferences_proxy).to receive(:list)
      .with(hash_including(friendly_name: Voice::Conference::Name.for(conversation), status: 'in-progress'))
      .and_return([conf_double])

    conference_context = double('conference_context')
    allow(conference_context).to receive(:update).with(status: 'completed')

    client_double = double('twilio_client')
    allow(client_double).to receive(:conferences).with(no_args).and_return(conferences_proxy)
    allow(client_double).to receive(:conferences).with('CF123').and_return(conference_context)

    allow(Twilio::REST::Client).to receive(:new)
      .with(voice_channel.provider_config_hash['account_sid'], voice_channel.provider_config_hash['auth_token'])
      .and_return(client_double)

    described_class.new(conversation: conversation).perform

    expect(conference_context).to have_received(:update).with(status: 'completed')
  end
end
