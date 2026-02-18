require 'rails_helper'

describe Whatsapp::IncomingMessageYcloudService do
  describe '#perform' do
    let!(:whatsapp_channel) { create(:channel_whatsapp, provider: 'ycloud', sync_templates: false, validate_provider_config: false) }

    context 'when receiving a text message' do
      let(:params) do
        {
          phone_number: whatsapp_channel.phone_number,
          type: 'whatsapp.inbound_message.received',
          whatsappInboundMessage: {
            id: 'msg_001',
            wamid: 'wamid.HBgNNTIxOTg3NjU0MzIx',
            from: '2423423243',
            to: whatsapp_channel.phone_number.delete('+'),
            customerProfile: { name: 'Sojan Jose' },
            type: 'text',
            text: { body: 'Hello from YCloud!' }
          }
        }.with_indifferent_access
      end

      it 'creates conversation, message and contact' do
        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform

        expect(whatsapp_channel.inbox.conversations.count).to eq(1)
        expect(Contact.all.first.name).to eq('Sojan Jose')
        expect(whatsapp_channel.inbox.messages.first.content).to eq('Hello from YCloud!')
        expect(whatsapp_channel.inbox.messages.first.source_id).to eq('wamid.HBgNNTIxOTg3NjU0MzIx')
      end
    end

    context 'when receiving an image attachment' do
      let(:params) do
        {
          phone_number: whatsapp_channel.phone_number,
          type: 'whatsapp.inbound_message.received',
          whatsappInboundMessage: {
            id: 'msg_002',
            wamid: 'wamid.image123',
            from: '2423423243',
            to: whatsapp_channel.phone_number.delete('+'),
            customerProfile: { name: 'Sojan Jose' },
            type: 'image',
            image: {
              id: 'media_img_001',
              link: 'https://ycloud-cdn.example.com/image.jpg',
              mime_type: 'image/jpeg',
              caption: 'Check this out!'
            }
          }
        }.with_indifferent_access
      end

      it 'creates message with attachment' do
        stub_request(:head, 'https://ycloud-cdn.example.com/image.jpg')
          .to_return(status: 200)
        stub_request(:get, 'https://ycloud-cdn.example.com/image.jpg')
          .to_return(status: 200, body: File.read('spec/assets/sample.png'), headers: { 'content-type' => 'image/jpeg' })

        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform

        expect(whatsapp_channel.inbox.conversations.count).to eq(1)
        expect(whatsapp_channel.inbox.messages.first.content).to eq('Check this out!')
        expect(whatsapp_channel.inbox.messages.first.attachments.present?).to be true
      end

      it 'triggers authorization_error! when media download returns 401' do
        stub_request(:head, 'https://ycloud-cdn.example.com/image.jpg')
          .to_return(status: 401)

        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform

        expect(whatsapp_channel.inbox.conversations.count).to eq(1)
        expect(whatsapp_channel.inbox.messages.first.content).to eq('Check this out!')
        expect(whatsapp_channel.inbox.messages.first.attachments.present?).to be false
        expect(whatsapp_channel.authorization_error_count).to eq(1)
      end

      it 'triggers authorization_error! when media download returns 403' do
        stub_request(:head, 'https://ycloud-cdn.example.com/image.jpg')
          .to_return(status: 403)

        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform

        expect(whatsapp_channel.authorization_error_count).to eq(1)
      end
    end

    context 'when receiving a status update' do
      let!(:message) do
        create(:message, message_type: :outgoing, inbox: whatsapp_channel.inbox,
                         source_id: 'wamid.status123',
                         conversation: create(:conversation, inbox: whatsapp_channel.inbox))
      end

      let(:delivered_params) do
        {
          phone_number: whatsapp_channel.phone_number,
          type: 'whatsapp.message.updated',
          whatsappMessage: {
            id: 'msg_003',
            wamid: 'wamid.status123',
            status: 'delivered'
          }
        }.with_indifferent_access
      end

      it 'updates message status to delivered' do
        described_class.new(inbox: whatsapp_channel.inbox, params: delivered_params).perform
        expect(message.reload.status).to eq('delivered')
      end

      context 'when status is failed with error' do
        let(:failed_params) do
          {
            phone_number: whatsapp_channel.phone_number,
            type: 'whatsapp.message.updated',
            whatsappMessage: {
              id: 'msg_004',
              wamid: 'wamid.status123',
              status: 'failed',
              whatsappApiError: true,
              errorCode: 131_047,
              errorMessage: 'Re-engagement message required'
            }
          }.with_indifferent_access
        end

        it 'updates message status to failed with error details' do
          described_class.new(inbox: whatsapp_channel.inbox, params: failed_params).perform
          expect(message.reload.status).to eq('failed')
          expect(message.reload.external_error).to eq('131047: Re-engagement message required')
        end
      end
    end

    context 'when receiving a message with reply context' do
      let(:params) do
        {
          phone_number: whatsapp_channel.phone_number,
          type: 'whatsapp.inbound_message.received',
          whatsappInboundMessage: {
            id: 'msg_005',
            wamid: 'wamid.reply456',
            from: '2423423243',
            to: whatsapp_channel.phone_number.delete('+'),
            customerProfile: { name: 'Test User' },
            type: 'text',
            text: { body: 'This is a reply' },
            context: { id: 'wamid.original789', from: '1234567890' }
          }
        }.with_indifferent_access
      end

      it 'preserves the reply context' do
        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform
        expect(whatsapp_channel.inbox.messages.first.content).to eq('This is a reply')
      end
    end

    context 'when receiving invalid params' do
      it 'does not raise error with empty whatsappInboundMessage' do
        params = {
          phone_number: whatsapp_channel.phone_number,
          type: 'whatsapp.inbound_message.received',
          whatsappInboundMessage: {}
        }.with_indifferent_access

        expect { described_class.new(inbox: whatsapp_channel.inbox, params: params).perform }.not_to raise_error
        expect(whatsapp_channel.inbox.conversations.count).to eq(0)
      end

      it 'does not raise error with unknown event type' do
        params = {
          phone_number: whatsapp_channel.phone_number,
          type: 'whatsapp.unknown.event'
        }.with_indifferent_access

        expect { described_class.new(inbox: whatsapp_channel.inbox, params: params).perform }.not_to raise_error
      end
    end
  end
end
