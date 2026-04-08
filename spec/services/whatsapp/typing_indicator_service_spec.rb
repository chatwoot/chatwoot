require 'rails_helper'

RSpec.describe Whatsapp::TypingIndicatorService do
  subject(:service) { described_class.new(conversation: conversation) }

  let(:whatsapp_channel) { create(:channel_whatsapp, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false) }
  let(:conversation) { create(:conversation, inbox: whatsapp_channel.inbox) }

  describe '#perform' do
    it 'calls the cloud provider when there is an inbound message with source_id' do
      create(:message, conversation: conversation, inbox: whatsapp_channel.inbox, message_type: :incoming, source_id: 'wamid.inbound')
      cloud = instance_spy(Whatsapp::Providers::WhatsappCloudService)
      allow(Whatsapp::Providers::WhatsappCloudService).to receive(:new).with(whatsapp_channel: whatsapp_channel).and_return(cloud)

      service.perform

      expect(cloud).to have_received(:send_typing_indicator).with('wamid.inbound')
    end

    it 'does nothing for non-whatsapp_cloud inboxes' do
      channel = create(:channel_whatsapp, provider: 'default', validate_provider_config: false, sync_templates: false)
      conv = create(:conversation, inbox: channel.inbox)
      create(:message, conversation: conv, inbox: channel.inbox, message_type: :incoming, source_id: 'wamid.inbound')

      expect(Whatsapp::Providers::WhatsappCloudService).not_to receive(:new)

      described_class.new(conversation: conv).perform
    end

    it 'does nothing when there is no inbound message' do
      expect(Whatsapp::Providers::WhatsappCloudService).not_to receive(:new)

      service.perform
    end
  end
end
