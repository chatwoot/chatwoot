require 'rails_helper'

describe Whatsapp::SendOnWhatsappService do
  template_params = {
    name: 'sample_shipping_confirmation',
    namespace: '23423423_2342423_324234234_2343224',
    language: 'en_US',
    category: 'Marketing',
    processed_params: { '1' => '3' }
  }

  describe '#perform' do
    before do
      stub_request(:post, 'https://waba.360dialog.io/v1/configs/webhook')
    end

    context 'when a valid message' do
      let(:whatsapp_request) { double }
      let!(:whatsapp_channel) { create(:channel_whatsapp, sync_templates: false) }
      let!(:contact_inbox) { create(:contact_inbox, inbox: whatsapp_channel.inbox, source_id: '123456789') }
      let!(:conversation) { create(:conversation, contact_inbox: contact_inbox, inbox: whatsapp_channel.inbox) }

      it 'calls channel.send_message when with in 24 hour limit' do
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

      it 'calls channel.send_template if template_params are present' do
        message = create(:message, additional_attributes: { template_params: template_params },
                                   content: 'Your package will be delivered in 3 business days.', conversation: conversation, message_type: :outgoing)
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

      it 'calls channel.send_template when template has regexp characters' do
        message = create(
          :message,
          message_type: :outgoing,
          content: 'عميلنا العزيز الرجاء الرد على هذه الرسالة بكلمة *نعم* للرد على إستفساركم من قبل خدمة العملاء.',
          conversation: conversation
        )
        allow(HTTParty).to receive(:post).and_return(whatsapp_request)
        allow(whatsapp_request).to receive(:success?).and_return(true)
        allow(whatsapp_request).to receive(:[]).with('messages').and_return([{ 'id' => '123456789' }])
        expect(HTTParty).to receive(:post).with(
          'https://waba.360dialog.io/v1/messages',
          headers: { 'D360-API-KEY' => 'test_key', 'Content-Type' => 'application/json' },
          body: {
            to: '123456789',
            template: {
              name: 'customer_yes_no',
              namespace: '2342384942_32423423_23423fdsdaf23',
              language: { 'policy': 'deterministic', 'code': 'ar' },
              components: [{ 'type': 'body', 'parameters': [] }]
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
