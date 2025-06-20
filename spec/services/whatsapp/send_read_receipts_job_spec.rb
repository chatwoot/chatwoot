require 'rails_helper'

RSpec.describe Whatsapp::SendReadReceiptsJob, type: :job do
  let(:account) { create(:account) }
  let(:whatsapp_channel) { create(:channel_whatsapp, provider: 'whapi', account: account) }
  let(:inbox) { create(:inbox, channel: whatsapp_channel, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox) }
  let(:conversation) { create(:conversation, contact: contact, inbox: inbox, contact_inbox: contact_inbox) }
  let!(:incoming_message) { create(:message, conversation: conversation, message_type: 'incoming', source_id: 'test_123') }

  describe '#perform' do
    context 'when conversation exists and is WhatsApp with Whapi provider' do
      let(:agent_last_seen_at) { Time.current }

      it 'sends read receipts for incoming messages' do
        expect(Whatsapp::SendReadReceiptService).to receive(:new).with(message: incoming_message).and_call_original
        expect_any_instance_of(Whatsapp::SendReadReceiptService).to receive(:perform)

        described_class.perform_now(conversation.id, agent_last_seen_at)
      end
    end

    context 'when conversation does not exist' do
      it 'does not send any read receipts' do
        expect(Whatsapp::SendReadReceiptService).not_to receive(:new)

        described_class.perform_now(999, Time.current)
      end
    end

    context 'when conversation is not WhatsApp' do
      let(:web_widget_channel) { create(:channel_widget, account: account) }
      let(:web_widget_inbox) { create(:inbox, channel: web_widget_channel, account: account) }
      let(:web_widget_conversation) { create(:conversation, contact: contact, inbox: web_widget_inbox, contact_inbox: contact_inbox) }

      it 'does not send any read receipts' do
        expect(Whatsapp::SendReadReceiptService).not_to receive(:new)

        described_class.perform_now(web_widget_conversation.id, Time.current)
      end
    end

    context 'when WhatsApp channel is not Whapi provider' do
      let(:cloud_whatsapp_channel) { create(:channel_whatsapp, provider: 'whatsapp_cloud', account: account) }
      let(:cloud_inbox) { create(:inbox, channel: cloud_whatsapp_channel, account: account) }
      let(:cloud_conversation) { create(:conversation, contact: contact, inbox: cloud_inbox, contact_inbox: contact_inbox) }

      it 'does not send any read receipts' do
        expect(Whatsapp::SendReadReceiptService).not_to receive(:new)

        described_class.perform_now(cloud_conversation.id, Time.current)
      end
    end
  end
end