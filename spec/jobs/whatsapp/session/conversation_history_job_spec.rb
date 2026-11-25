require 'rails_helper'

RSpec.describe Whatsapp::Session::ConversationHistoryJob do
  let(:channel) do
    create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false, sync_templates: false,
                              provider_config: { 'webhook_verify_token' => 'x' })
  end
  let(:conversation) { create(:conversation, account: channel.account, inbox: channel.inbox) }

  it 'asks the provider for the history behind this thread' do
    service = instance_double(Whatsapp::Providers::WhatsappBaileysService, request_history: true)
    allow(channel).to receive(:provider_service).and_return(service)
    allow_any_instance_of(Inbox).to receive(:channel).and_return(channel) # rubocop:disable RSpec/AnyInstance

    described_class.perform_now(conversation)

    expect(service).to have_received(:request_history).with(conversation.contact)
  end

  it 'files nothing on an inbox whose provider cannot fetch history' do
    plain = create(:conversation, account: channel.account)

    expect { described_class.perform_now(plain) }.not_to raise_error
  end

  # One number no longer on WhatsApp, or a chat the provider refuses, is not a reason for
  # the press to surface as a failed job the operator never sees.
  it 'swallows a provider that refuses the request' do
    service = instance_double(Whatsapp::Providers::WhatsappBaileysService)
    allow(service).to receive(:request_history).and_raise(Whatsapp::Session::Errors::ProviderUnavailable)
    allow(channel).to receive(:provider_service).and_return(service)
    allow_any_instance_of(Inbox).to receive(:channel).and_return(channel) # rubocop:disable RSpec/AnyInstance

    expect { described_class.perform_now(conversation) }.not_to raise_error
  end
end
