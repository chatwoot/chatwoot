require 'rails_helper'

describe Whatsapp::SendOnWhatsappService do
  describe '#perform' do
    context 'when a valid message' do
      it 'calls channel.send_message' do
        whatsapp_request = double
        whatsapp_channel = create(:channel_whatsapp)
        contact_inbox = create(:contact_inbox, inbox: whatsapp_channel.inbox, source_id: '123456789')
        conversation = create(:conversation, contact_inbox: contact_inbox, inbox: whatsapp_channel.inbox)
        message = create(:message, message_type: :outgoing, content: 'test',
                                   conversation: conversation)
        allow(HTTParty).to receive(:post).and_return(whatsapp_request)
        expect(HTTParty).to receive(:post).with(
          'https://waba.360dialog.io/v1/messages',
          headers: { 'D360-API-KEY': 'test_key', 'Content-Type': 'application/json' },
          body: { to: '123456789', text: { body: 'test' }, type: 'text' }.to_json
        )
        described_class.new(message: message).perform
      end
    end
  end
end
