require 'rails_helper'

RSpec.describe Integrations::Jusmonitoria::ProcessorService do
  describe '#perform' do
    it 'forwards incoming lead messages even when the conversation has no monitoring label' do
      account = create(:account)
      conversation = create(:conversation, account: account)
      message = create(
        :message,
        account: account,
        inbox: conversation.inbox,
        conversation: conversation,
        message_type: :incoming
      )
      hook = instance_double(Integrations::Hook, id: 127, settings: {}, account: account)
      response = instance_double(HTTParty::Response, success?: false)

      allow(Integrations::Jusmonitoria::WebhookForwarderService).to receive(:forward_event).and_return(response)

      described_class.new(event_name: 'message.created', hook: hook, event_data: { message: message }).perform

      expect(Integrations::Jusmonitoria::WebhookForwarderService).to have_received(:forward_event).with(
        event_type: 'message.received',
        account: account,
        payload: hash_including(
          message: message.webhook_data,
          contact: conversation.contact.webhook_data,
          conversation: hash_including(labels: []),
          inbox: hash_including(id: conversation.inbox.id)
        )
      )
    end
  end

  describe '#inbox_payload' do
    it 'includes the WhatsApp provider so JusMonitorIA can choose template or text delivery' do
      channel = create(:channel_whatsapp, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false)
      processor = described_class.new(event_name: 'message.created', hook: instance_double(Integrations::Hook, id: 1), event_data: {})

      payload = processor.send(:inbox_payload, channel.inbox)

      expect(payload).to include(
        id: channel.inbox.id,
        channel_type: 'Channel::Whatsapp',
        provider: 'whatsapp_cloud'
      )
    end
  end
end
