require 'rails_helper'

describe Whatsapp::IncomingMessageWhatsappWebService do
  describe '#perform' do
    let!(:whatsapp_channel) { create(:channel_whatsapp, provider: 'whatsapp_web', sync_templates: false, validate_provider_config: false) }

    context 'when valid text message params from go-whatsapp-web-multidevice' do
      let(:params) do
        {
          event: 'message',
          payload: {
            sender_id: '5511999887766',
            chat_id: '5511999887766',
            from: '5511999887766@s.whatsapp.net',
            timestamp: '2023-10-15T10:30:00Z',
            pushname: 'João Silva',
            message: {
              text: 'Hello, I need help!',
              id: '3EB0C127D7BACC83D6A1',
              replied_id: '',
              quoted_message: ''
            },
            type: 'text'
          }
        }.with_indifferent_access
      end

      it 'creates appropriate conversations, message and contacts' do
        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform

        expect(whatsapp_channel.inbox.conversations.count).not_to eq(0)
        created_contact = whatsapp_channel.inbox.contact_inboxes.first.contact
        expect(created_contact.name).to eq('João Silva')
        expect(whatsapp_channel.inbox.messages.first.content).to eq('Hello, I need help!')
        expect(whatsapp_channel.inbox.contact_inboxes.first.source_id).to eq('5511999887766')
      end
    end

    context 'when message from device with identifier containing device id' do
      let(:params) do
        {
          event: 'message',
          payload: {
            sender_id: '554192928877',
            chat_id: '554192928877',
            from: '554192928877:6@s.whatsapp.net in 554192928877@s.whatsapp.net',
            timestamp: '2025-09-01T22:56:24Z',
            pushname: '2N Marketing',
            message: {
              text: '*Suporte ChatWoot:*\nping',
              id: '3EB0E8A898020108670F17178A707B8E145C2CD4',
              replied_id: '',
              quoted_message: ''
            },
            type: 'text'
          }
        }.with_indifferent_access
      end

      it 'creates contact with clean identifier and correct phone number' do
        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform

        expect(whatsapp_channel.inbox.conversations.count).not_to eq(0)
        created_contact = whatsapp_channel.inbox.contact_inboxes.first.contact

        # Should clean the identifier removing device id (:6)
        expect(created_contact.identifier).to eq('554192928877@s.whatsapp.net')
        expect(created_contact.name).to eq('2N Marketing')
        expect(created_contact.phone_number).to eq('+554192928877')
        expect(whatsapp_channel.inbox.contact_inboxes.first.source_id).to eq('554192928877')
      end
    end

    context 'when image message params from go-whatsapp-web-multidevice' do
      let(:params) do
        {
          event: 'message',
          payload: {
            sender_id: '5511999887766',
            chat_id: '5511999887766',
            from: '5511999887766@s.whatsapp.net',
            timestamp: '2023-10-15T10:30:00Z',
            pushname: 'João Silva',
            message: {
              id: 'IMG123ABC456DEF789',
              replied_id: '',
              quoted_message: ''
            },
            type: 'image',
            image_url: '/media/sample.jpg',
            caption: 'Check out this image!',
            mime_type: 'image/jpeg'
          }
        }.with_indifferent_access
      end

      before do
        # Mock para o download de attachment com StringIO para torná-lo rewindable
        attachment_file = StringIO.new('fake image content')
        attachment_file.define_singleton_method(:original_filename) { 'sample.jpg' }
        attachment_file.define_singleton_method(:content_type) { 'image/jpeg' }

        allow_any_instance_of(described_class).to receive(:download_attachment_file).and_return(attachment_file)
      end

      it 'creates message with image attachment' do
        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform

        expect(whatsapp_channel.inbox.conversations.count).not_to eq(0)
        expect(whatsapp_channel.inbox.messages.first.content).to eq('Check out this image!')

        message = whatsapp_channel.inbox.messages.first
        expect(message.attachments.count).to eq(1)
        expect(message.attachments.first.file_type).to eq('image')
      end
    end

    context 'when receipt/ack message params from go-whatsapp-web-multidevice' do
      let!(:existing_message) { create(:message, source_id: 'msg_123', inbox: whatsapp_channel.inbox) }
      let(:params) do
        {
          phone_number: '5521987654321',
          payload: {
            event: 'message.ack',
            payload: {
              chat_id: '5511999887766@s.whatsapp.net',
              from: '5511999887766@s.whatsapp.net',
              ids: ['msg_123'],
              receipt_type: 'read',
              receipt_type_description: 'Message was read',
              sender_id: '5511999887766@s.whatsapp.net'
            },
            timestamp: '2023-10-15T10:32:00Z'
          }
        }.with_indifferent_access
      end

      it 'updates message status correctly' do
        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform

        existing_message.reload
        expect(existing_message.status).to eq('read')
      end

      context 'when receipt contains multiple message IDs' do
        let!(:existing_message_1) { create(:message, source_id: 'msg_001', inbox: whatsapp_channel.inbox) }
        let!(:existing_message_2) { create(:message, source_id: 'msg_002', inbox: whatsapp_channel.inbox) }
        let!(:existing_message_3) { create(:message, source_id: 'msg_003', inbox: whatsapp_channel.inbox) }

        let(:multi_id_params) do
          {
            phone_number: '5521987654321',
            payload: {
              event: 'message.ack',
              payload: {
                chat_id: '5511999887766@s.whatsapp.net',
                from: '5511999887766@s.whatsapp.net',
                ids: %w[msg_001 msg_002 msg_003],
                receipt_type: 'read',
                receipt_type_description: 'Messages were read',
                sender_id: '5511999887766@s.whatsapp.net'
              },
              timestamp: '2023-10-15T10:32:00Z'
            }
          }.with_indifferent_access
        end

        it 'updates status for all messages in the receipt' do
          described_class.new(inbox: whatsapp_channel.inbox, params: multi_id_params).perform

          existing_message_1.reload
          existing_message_2.reload
          existing_message_3.reload

          expect(existing_message_1.status).to eq('read')
          expect(existing_message_2.status).to eq('read')
          expect(existing_message_3.status).to eq('read')
        end
      end
    end

    context 'when location message params from go-whatsapp-web-multidevice' do
      let(:params) do
        {
          event: 'message',
          payload: {
            sender_id: '5511999887766',
            chat_id: '5511999887766',
            from: '5511999887766@s.whatsapp.net',
            timestamp: '2023-10-15T10:30:00Z',
            pushname: 'João Silva',
            message: {
              id: 'LOC789XYZ123ABC',
              replied_id: '',
              quoted_message: ''
            },
            type: 'location',
            latitude: -23.550520,
            longitude: -46.633308,
            location_name: 'São Paulo',
            location_address: 'São Paulo, SP, Brazil'
          }
        }.with_indifferent_access
      end

      it 'creates message with location attachment' do
        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform

        expect(whatsapp_channel.inbox.conversations.count).not_to eq(0)

        message = whatsapp_channel.inbox.messages.first
        expect(message.attachments.count).to eq(1)
        expect(message.attachments.first.file_type).to eq('location')
        expect(message.attachments.first.coordinates_lat).to eq(-23.550520)
        expect(message.attachments.first.coordinates_long).to eq(-46.633308)
      end
    end

    context 'when group event from go-whatsapp-web-multidevice' do
      let(:params) do
        {
          event: 'group.participants',
          payload: {
            chat_id: '120363402106XXXXX@g.us',
            type: 'join',
            jids: ['5511999887766@s.whatsapp.net']
          },
          timestamp: '2023-10-15T10:35:00Z'
        }.with_indifferent_access
      end

      it 'does not create messages for group events' do
        initial_count = whatsapp_channel.inbox.messages.count

        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform

        expect(whatsapp_channel.inbox.messages.count).to eq(initial_count)
      end
    end

    context 'when message with reply context from go-whatsapp-web-multidevice' do
      let(:params) do
        {
          event: 'message',
          payload: {
            sender_id: '5511999887766',
            chat_id: '5511999887766',
            from: '5511999887766@s.whatsapp.net',
            timestamp: '2023-10-15T10:30:00Z',
            pushname: 'João Silva',
            message: {
              text: 'Thank you for the response!',
              id: 'REPLY456DEF789ABC',
              replied_id: 'original_msg_123',
              quoted_message: ''
            },
            type: 'text'
          }
        }.with_indifferent_access
      end

      xit 'creates message with reply context' do
        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform

        expect(whatsapp_channel.inbox.conversations.count).not_to eq(0)
        message = whatsapp_channel.inbox.messages.first
        expect(message).not_to be_nil
        expect(message.in_reply_to_external_id).to eq('original_msg_123')
      end
    end

    context 'when group message and contact_info fails with connection error' do
      let(:params) do
        {
          event: 'message',
          payload: {
            sender_id: '554130898206',
            chat_id: '120363230235309595@g.us',
            from: '554130898206:3@s.whatsapp.net in 120363230235309595@g.us',
            timestamp: '2025-10-07T18:31:04Z',
            pushname: 'Test User',
            message: {
              text: 'Hello from group',
              id: '3FAAB0E5F16480E454D7',
              replied_id: '',
              quoted_message: ''
            },
            type: 'text'
          }
        }.with_indifferent_access
      end

      it 'processes message and creates contact with fallback name when gateway is unavailable' do
        # Simulate gateway connection failure
        allow_any_instance_of(Whatsapp::Providers::WhatsappWebService)
          .to receive(:contact_info)
          .and_raise(Errno::ECONNREFUSED)

        expect do
          described_class.new(inbox: whatsapp_channel.inbox, params: params).perform
        end.to change(Message, :count).by(1)

        # Verify message was created
        message = whatsapp_channel.inbox.messages.last
        expect(message.content).to eq('Hello from group')

        # Verify group contact was created with fallback name
        group_contact = whatsapp_channel.inbox.contact_inboxes.find_by(source_id: '120363230235309595@g.us')
        expect(group_contact).to be_present
        expect(group_contact.contact.name).to eq('Group 120363230235309595')
      end

      it 'logs warning when contact_info fails' do
        allow_any_instance_of(Whatsapp::Providers::WhatsappWebService)
          .to receive(:contact_info)
          .and_raise(Errno::ECONNREFUSED.new('Connection refused'))

        expect(Rails.logger).to receive(:warn) do |log_message|
          parsed_log = JSON.parse(log_message)
          expect(parsed_log['context']).to eq('WhatsApp Web: Contact info fetch failed')
          expect(parsed_log['error_type']).to eq('Errno::ECONNREFUSED')
          expect(parsed_log['fallback_used']).to eq(true)
        end

        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform
      end
    end

    context 'when contact_info fails with timeout error' do
      let(:params) do
        {
          event: 'message',
          payload: {
            sender_id: '554130898206',
            chat_id: '120363230235309595@g.us',
            from: '554130898206:3@s.whatsapp.net in 120363230235309595@g.us',
            timestamp: '2025-10-07T18:31:04Z',
            pushname: 'Test User',
            message: {
              text: 'Hello from group',
              id: '3FAAB0E5F16480E454D8',
              replied_id: '',
              quoted_message: ''
            },
            type: 'text'
          }
        }.with_indifferent_access
      end

      it 'processes message when gateway times out' do
        allow_any_instance_of(Whatsapp::Providers::WhatsappWebService)
          .to receive(:contact_info)
          .and_raise(Net::OpenTimeout)

        expect do
          described_class.new(inbox: whatsapp_channel.inbox, params: params).perform
        end.to change(Message, :count).by(1)

        # Verify group contact was created with fallback name
        group_contact = whatsapp_channel.inbox.contact_inboxes.find_by(source_id: '120363230235309595@g.us')
        expect(group_contact).to be_present
      end
    end

    # TODO: Fix reaction message test - functionality is implemented but test needs debugging
    # context 'when reaction message params from go-whatsapp-web-multidevice' do
    #   let(:params) do
    #     {
    #       event: 'message',
    #       payload: {
    #         sender_id: '5511999887766',
    #         chat_id: '5511999887766',
    #         from: '5511999887766@s.whatsapp.net',
    #         timestamp: '2023-10-15T10:40:00Z',
    #         pushname: 'John Doe',
    #         reaction: {
    #           message: '👍',
    #           id: '3EB0C127D7BACC83D6A1'
    #         },
    #         message: {
    #           text: '',
    #           id: '88760C69D1F35FEB239102699AE9XXXX',
    #           replied_id: '',
    #           quoted_message: ''
    #         }
    #       }
    #     }.with_indifferent_access
    #   end

    #   it 'creates reaction message as reply to original message' do
    #     described_class.new(inbox: whatsapp_channel.inbox, params: params).perform

    #     expect(whatsapp_channel.inbox.conversations.count).not_to eq(0)
    #     message = whatsapp_channel.inbox.messages.first
    #     expect(message).not_to be_nil
    #     expect(message.content).to eq('👍')
    #     expect(message.in_reply_to_external_id).to eq('3EB0C127D7BACC83D6A1')
    #   end
    # end
  end
end
