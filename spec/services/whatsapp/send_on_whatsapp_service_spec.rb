require 'rails_helper'

describe Whatsapp::SendOnWhatsappService do
  describe '#perform' do
    before do
      stub_request(:post, 'https://waba.360dialog.io/v1/configs/webhook')
    end

    context 'when a valid message' do
      it 'calls channel.send_message when with in 24 hour limit' do
        whatsapp_request = double
        whatsapp_channel = create(:channel_whatsapp)
        contact_inbox = create(:contact_inbox, inbox: whatsapp_channel.inbox, source_id: '123456789')
        conversation = create(:conversation, contact_inbox: contact_inbox, inbox: whatsapp_channel.inbox)
        # to handle the case of 24 hour window limit.
        create(:message, message_type: :incoming, content: 'test',
                         conversation: conversation)
        message = create(:message, message_type: :outgoing, content: 'test',
                                   conversation: conversation)
        allow(HTTParty).to receive(:post).and_return(whatsapp_request)
        allow(whatsapp_request).to receive(:success?).and_return(true)
        allow(whatsapp_request).to receive(:[]).with('messages').and_return([{ 'id' => '123456789' }])
        expect(HTTParty).to receive(:post).with(
          'https://waba.360dialog.io/v1/messages',
          headers: { 'D360-API-KEY' => 'test_key', 'Content-Type' => 'application/json' },
          body: { 'to' => '123456789', 'text' => { 'body' => 'test' }, 'type' => 'text' }.to_json
        )
        described_class.new(message: message).perform
        expect(message.reload.source_id).to eq('123456789')
      end

      it 'calls channel.send_template when after 24 hour limit' do
        whatsapp_request = double
        whatsapp_channel = create(:channel_whatsapp)
        contact_inbox = create(:contact_inbox, inbox: whatsapp_channel.inbox, source_id: '123456789')
        conversation = create(:conversation, contact_inbox: contact_inbox, inbox: whatsapp_channel.inbox)
        message = create(:message, message_type: :outgoing, content: 'Your package has been shipped. It will be delivered in 3 business days.',
                                   conversation: conversation)
        allow(HTTParty).to receive(:post).and_return(whatsapp_request)
        allow(whatsapp_request).to receive(:success?).and_return(true)
        allow(whatsapp_request).to receive(:[]).with('messages').and_return([{ 'id' => '123456789' }])
        expect(HTTParty).to receive(:post).with(
          'https://waba.360dialog.io/v1/messages',
          headers: { 'D360-API-KEY' => 'test_key', 'Content-Type' => 'application/json' },
          body: {
            to: '123456789',
            template: {
              name: 'sample_shipping_confirmation',
              namespace: '23423423_2342423_324234234_2343224',
              language: { 'policy': 'deterministic', 'code': 'en_US' },
              components: [{ 'type': 'body', 'parameters': [{ 'type': 'text', 'text': '3' }] }]
            },
            type: 'template'
          }.to_json
        )
        described_class.new(message: message).perform
        expect(message.reload.source_id).to eq('123456789')
      end
    end
  end
end
