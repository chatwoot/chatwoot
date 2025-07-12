require 'rails_helper'

describe Whatsapp::IncomingMessageWhapiService do
  describe '#perform' do
    let!(:whatsapp_channel) { create(:channel_whatsapp, provider: 'whapi', sync_templates: false, validate_provider_config: false) }
    let(:wa_id) { '2423423243' }
    let(:connected_number) { whatsapp_channel.phone_number.delete('+') }

    before do
      # Stub WHAPI provider validation HTTP request
      stub_request(:get, 'https://gate.whapi.cloud/health')
        .with(headers: { 'Authorization' => 'Bearer test_key' })
        .to_return(status: 200, body: '', headers: {})
    end

    describe 'incoming messages (from_me: false)' do
      let(:incoming_params) do
        {
          'contacts' => [{ 'profile' => { 'name' => 'Sojan Jose' }, 'wa_id' => wa_id }],
          'messages' => [{
            'from' => wa_id,
            'to' => connected_number,
            'id' => 'SDFADSf23sfasdafasdfa',
            'text' => { 'body' => 'Test incoming message' },
            'timestamp' => '1633034394',
            'type' => 'text',
            'from_me' => false
          }]
        }.with_indifferent_access
      end

      it 'creates appropriate conversations, message and contacts for incoming messages' do
        described_class.new(inbox: whatsapp_channel.inbox, params: incoming_params).perform

        expect(whatsapp_channel.inbox.conversations.count).to eq(1)
        contact = Contact.find_by(phone_number: "+#{wa_id}")
        expect(contact.name).to eq('Sojan Jose')
        expect(whatsapp_channel.inbox.messages.first.content).to eq('Test incoming message')
        expect(whatsapp_channel.inbox.messages.first.message_type).to eq('incoming')
        expect(whatsapp_channel.inbox.messages.first.sender).to eq(contact)
      end

      it 'creates contact for incoming messages' do
        described_class.new(inbox: whatsapp_channel.inbox, params: incoming_params).perform

        contact = Contact.find_by(phone_number: "+#{wa_id}")
        expect(contact.name).to eq('Sojan Jose')
        expect(contact.phone_number).to eq("+#{wa_id}")
      end
    end

    xdescribe 'outgoing messages (from_me: true)' do
      let(:outgoing_params) do
        {
          'messages' => [{
            'from' => connected_number,
            'to' => wa_id,
            'id' => 'outgoing_message_id',
            'text' => { 'body' => 'Test outgoing message' },
            'timestamp' => '1633034394',
            'type' => 'text',
            'from_me' => true
          }]
        }.with_indifferent_access
      end

      context 'when contact and conversation exist' do
        let!(:contact) { create(:contact, account: whatsapp_channel.account, phone_number: "+#{wa_id}") }
        let!(:contact_inbox) { create(:contact_inbox, inbox: whatsapp_channel.inbox, source_id: wa_id, contact: contact) }
        let!(:conversation) { create(:conversation, inbox: whatsapp_channel.inbox, contact_inbox: contact_inbox) }

        it 'creates outgoing message in existing conversation' do
          described_class.new(inbox: whatsapp_channel.inbox, params: outgoing_params).perform

          message = whatsapp_channel.inbox.messages.first
          expect(message.content).to eq('Test outgoing message')
          expect(message.message_type).to eq('outgoing')
          expect(message.sender).to be_nil # Agent/system message
          expect(message.conversation).to eq(conversation)
        end

        it 'does not create a new conversation for outgoing messages' do
          expect do
            described_class.new(inbox: whatsapp_channel.inbox, params: outgoing_params).perform
          end.not_to change(Conversation, :count)
        end
      end

      context 'when contact does not exist' do
        it 'creates contact and conversation for outgoing messages' do
          described_class.new(inbox: whatsapp_channel.inbox, params: outgoing_params).perform

          contact = Contact.find_by(phone_number: "+#{wa_id}")
          expect(contact).to be_present
          expect(contact.name).to eq(wa_id) # Uses wa_id as name when no contact info

          message = whatsapp_channel.inbox.messages.first
          expect(message.content).to eq('Test outgoing message')
          expect(message.message_type).to eq('outgoing')
        end
      end
    end

    xdescribe 'mixed messages (both incoming and outgoing)' do
      let(:mixed_params) do
        {
          'contacts' => [{ 'profile' => { 'name' => 'Sojan Jose' }, 'wa_id' => wa_id }],
          'messages' => [
            {
              'from' => wa_id,
              'to' => connected_number,
              'id' => 'incoming_msg_id',
              'text' => { 'body' => 'Hello from customer' },
              'timestamp' => '1633034394',
              'type' => 'text',
              'from_me' => false
            },
            {
              'from' => connected_number,
              'to' => wa_id,
              'id' => 'outgoing_msg_id',
              'text' => { 'body' => 'Reply from agent' },
              'timestamp' => '1633034400',
              'type' => 'text',
              'from_me' => true
            }
          ]
        }.with_indifferent_access
      end

      it 'processes both incoming and outgoing messages correctly' do
        described_class.new(inbox: whatsapp_channel.inbox, params: mixed_params).perform

        messages = whatsapp_channel.inbox.messages.order(:created_at)
        expect(messages.count).to eq(2)

        # First message (incoming)
        incoming_msg = messages.first
        expect(incoming_msg.content).to eq('Hello from customer')
        expect(incoming_msg.message_type).to eq('incoming')

        # Second message (outgoing)
        outgoing_msg = messages.last
        expect(outgoing_msg.content).to eq('Reply from agent')
        expect(outgoing_msg.message_type).to eq('outgoing')

        # Both messages should be in the same conversation
        expect(incoming_msg.conversation).to eq(outgoing_msg.conversation)
      end
    end

    describe 'attachment messages' do
      let(:attachment_params) do
        {
          'contacts' => [{ 'profile' => { 'name' => 'Sojan Jose' }, 'wa_id' => wa_id }],
          'messages' => [{
            'from' => wa_id,
            'id' => 'attachment_msg_id',
            'image' => {
              'link' => 'https://example.com/image.jpg',
              'mime_type' => 'image/jpeg',
              'caption' => 'Check out this image!'
            },
            'timestamp' => '1633034394',
            'type' => 'image',
            'from_me' => false
          }]
        }.with_indifferent_access
      end

      it 'handles attachment messages with direct links' do
        stub_request(:get, 'https://example.com/image.jpg')
          .to_return(status: 200, body: File.read('spec/assets/sample.png'))

        described_class.new(inbox: whatsapp_channel.inbox, params: attachment_params).perform

        message = whatsapp_channel.inbox.messages.first
        expect(message.content).to eq('Check out this image!')
        expect(message.attachments.present?).to be true
      end

      it 'handles attachment download failure gracefully' do
        stub_request(:get, 'https://example.com/image.jpg')
          .to_return(status: 404)

        described_class.new(inbox: whatsapp_channel.inbox, params: attachment_params).perform

        message = whatsapp_channel.inbox.messages.first
        expect(message.content).to eq('Check out this image!')
        expect(message.attachments.present?).to be false
      end
    end

    describe 'quoted messages' do
      let(:quoted_params) do
        {
          'contacts' => [{ 'profile' => { 'name' => 'Sojan Jose' }, 'wa_id' => wa_id }],
          'messages' => [{
            'from' => wa_id,
            'id' => 'quoted_msg_id',
            'text' => { 'body' => 'This is a reply' },
            'context' => { 'quoted_id' => 'original_message_id' },
            'timestamp' => '1633034394',
            'type' => 'text',
            'from_me' => false
          }]
        }.with_indifferent_access
      end

      xit 'handles quoted messages correctly' do
        described_class.new(inbox: whatsapp_channel.inbox, params: quoted_params).perform

        message = whatsapp_channel.inbox.messages.first
        expect(message.content).to eq('This is a reply')
        expect(message.content_attributes[:in_reply_to_external_id]).to eq('original_message_id')
      end
    end

    describe 'status updates' do
      let(:status_params) do
        {
          'statuses' => [{
            'id' => 'message_id_123',
            'recipient_id' => wa_id,
            'status' => 'read',
            'timestamp' => '1633034394'
          }]
        }.with_indifferent_access
      end

      let!(:contact) { create(:contact, account: whatsapp_channel.account, phone_number: "+#{wa_id}") }
      let!(:contact_inbox) { create(:contact_inbox, inbox: whatsapp_channel.inbox, source_id: wa_id, contact: contact) }
      let!(:conversation) { create(:conversation, inbox: whatsapp_channel.inbox, contact_inbox: contact_inbox) }
      let!(:message) { create(:message, conversation: conversation, source_id: 'message_id_123', message_type: 'outgoing') }

      it 'updates message status correctly' do
        expect(message.status).to eq('sent')

        described_class.new(inbox: whatsapp_channel.inbox, params: status_params).perform

        expect(message.reload.status).to eq('read')
      end
    end

    describe 'error handling' do
      it 'handles empty params gracefully' do
        expect do
          described_class.new(inbox: whatsapp_channel.inbox, params: {}).perform
        end.not_to raise_error
      end

      it 'handles malformed message params gracefully' do
        malformed_params = {
          'messages' => [{
            'from' => wa_id,
            'type' => 'text'
            # Missing required fields
          }]
        }.with_indifferent_access

        expect do
          described_class.new(inbox: whatsapp_channel.inbox, params: malformed_params).perform
        end.not_to raise_error
      end
    end

    describe 'duplicate message handling' do
      let(:duplicate_params) do
        {
          'contacts' => [{ 'profile' => { 'name' => 'Sojan Jose' }, 'wa_id' => wa_id }],
          'messages' => [{
            'from' => wa_id,
            'id' => 'duplicate_msg_id',
            'text' => { 'body' => 'Test message' },
            'timestamp' => '1633034394',
            'type' => 'text',
            'from_me' => false
          }]
        }.with_indifferent_access
      end

      it 'prevents duplicate message creation' do
        # First call
        described_class.new(inbox: whatsapp_channel.inbox, params: duplicate_params).perform
        expect(whatsapp_channel.inbox.messages.count).to eq(1)

        # Second call with same message ID
        described_class.new(inbox: whatsapp_channel.inbox, params: duplicate_params).perform
        expect(whatsapp_channel.inbox.messages.count).to eq(1) # Should not create duplicate
      end
    end
  end
end