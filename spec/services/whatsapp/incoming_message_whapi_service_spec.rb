require 'rails_helper'

RSpec.describe Whatsapp::IncomingMessageWhapiService do
  let!(:account) { create(:account) }
  let!(:channel) do
    create(:channel_whatsapp, account: account, provider: 'whapi',
                              provider_config: { 'api_key' => 'test_api_key', 'business_account_id' => '123456789' },
                              validate_provider_config: false)
  end
  let!(:inbox) { create(:inbox, channel: channel, account: account) }

  # Default stub for WHAPI contact fetch (returns empty response)
  before do
    stub_request(:get, %r{https://gate\.whapi\.cloud/contacts/\d+})
      .to_return(status: 404, body: '{"error": "Contact not found"}', headers: { 'Content-Type' => 'application/json' })
  end

  describe '#perform' do
    context 'when receiving incoming messages' do
      let(:contact_name) { 'John Doe' }
      let(:phone_number) { '123456789' }
      let(:message_id) { 'whapi_message_1' }
      let(:message_params) do
        {
          'messages' => [
            {
              'id' => message_id,
              'from' => phone_number,
              'from_name' => contact_name,
              'from_me' => false,
              'type' => 'text',
              'text' => { 'body' => 'Hello' },
              'timestamp' => Time.now.to_i
            }
          ]
        }
      end

      it 'creates a new contact, conversation, and message for a new contact' do
        expect { described_class.new(inbox: inbox, params: message_params).perform }
          .to change(Contact, :count).by(1)
          .and change(Conversation, :count).by(1)
          .and change(Message, :count).by(1)

        contact = Contact.last
        expect(contact.name).to eq(contact_name)
        expect(contact.phone_number).to eq("+#{phone_number}")

        message = Message.last
        expect(message.content).to eq('Hello')
        expect(message.source_id).to eq(message_id)
        expect(message.incoming?).to be(true)
      end

      it 'does not create a new contact if one already exists' do
        contact = create(:contact, account: account, phone_number: "+#{phone_number}")
        create(:contact_inbox, inbox: inbox, source_id: phone_number, contact: contact)

        expect { described_class.new(inbox: inbox, params: message_params).perform }
          .to change(Contact, :count).by(0)
          .and change(Conversation, :count).by(1)
          .and change(Message, :count).by(1)
      end

      it 'appends to an existing open conversation' do
        contact_inbox = create(:contact_inbox, inbox: inbox, source_id: phone_number)
        create(:conversation, contact_inbox: contact_inbox, status: :open)

        expect { described_class.new(inbox: inbox, params: message_params).perform }
          .to change(Conversation, :count).by(0)
          .and change(Message, :count).by(1)
      end

      it 'creates a new conversation if the last one is resolved' do
        contact_inbox = create(:contact_inbox, inbox: inbox, source_id: phone_number)
        create(:conversation, contact_inbox: contact_inbox, status: :resolved)

        expect { described_class.new(inbox: inbox, params: message_params).perform }
          .to change(Conversation, :count).by(1)
          .and change(Message, :count).by(1)
      end

      context 'when lock_to_single_conversation is enabled' do
        before do
          inbox.update!(lock_to_single_conversation: true)
        end

        it 'appends to the last conversation regardless of status' do
          contact_inbox = create(:contact_inbox, inbox: inbox, source_id: phone_number)
          create(:conversation, contact_inbox: contact_inbox, status: :resolved)

          expect { described_class.new(inbox: inbox, params: message_params).perform }
            .to change(Conversation, :count).by(0)
            .and change(Message, :count).by(1)
        end
      end

      it 'ignores duplicate messages' do
        create(:message, source_id: message_id, inbox: inbox)
        expect { described_class.new(inbox: inbox, params: message_params).perform }
          .not_to change(Message, :count)
      end

      context 'with attachments' do
        let(:media_message_params) do
          {
            'messages' => [
              {
                'id' => 'whapi_media_message',
                'from' => phone_number,
                'from_name' => contact_name,
                'from_me' => false,
                'type' => 'image',
                'image' => {
                  'link' => 'https://example.com/image.jpg',
                  'caption' => 'This is an image'
                },
                'timestamp' => Time.now.to_i
              }
            ]
          }
        end

        it 'creates a message with an attachment' do
          stub_request(:get, 'https://example.com/image.jpg')
            .to_return(status: 200, body: File.read('spec/assets/sample.png'), headers: { 'Content-Type' => 'image/png' })

          expect { described_class.new(inbox: inbox, params: media_message_params).perform }
            .to change(Message, :count).by(1)

          message = Message.last
          expect(message.attachments.count).to eq(1)
          expect(message.content).to eq('This is an image')
          expect(message.attachments.first.file_type).to eq('image')
        end
      end
    end

    context 'when receiving outgoing message echoes' do
      let!(:contact) { create(:contact, account: account, phone_number: '+987654321') }
      let!(:contact_inbox) { create(:contact_inbox, inbox: inbox, contact: contact, source_id: '987654321') }
      let!(:conversation) { create(:conversation, contact_inbox: contact_inbox, inbox: inbox, contact: contact) }
      let(:outgoing_message_id) { 'whapi_outgoing_1' }
      let(:outgoing_params) do
        {
          'messages' => [
            {
              'id' => outgoing_message_id,
              'to' => '987654321',
              'chat_id' => '987654321@c.us',
              'from_me' => true,
              'type' => 'text',
              'text' => { 'body' => 'This is an echo' },
              'timestamp' => Time.now.to_i
            }
          ]
        }
      end

      it 'creates an outgoing message in the correct conversation' do
        expect { described_class.new(inbox: inbox, params: outgoing_params).perform }
          .to change(conversation.messages, :count).by(1)

        message = conversation.messages.last
        expect(message.content).to eq('This is an echo')
        expect(message.source_id).to eq(outgoing_message_id)
        expect(message.outgoing?).to be(true)
        expect(message.sender).to be_nil
      end

      it 'ignores echoes for unknown contacts' do
        unknown_contact_params = outgoing_params.deep_dup
        unknown_contact_params['messages'].first.merge!('to' => 'unknown', 'chat_id' => 'unknown@c.us')
        expect { described_class.new(inbox: inbox, params: unknown_contact_params).perform }
          .not_to change(Message, :count)
      end
    end

    context 'when receiving status updates' do
      let!(:message) { create(:message, source_id: 'status_message_id', inbox: inbox) }
      let(:status_params) do
        {
          'statuses' => [
            {
              'id' => 'status_message_id',
              'status' => 'read',
              'timestamp' => Time.now.to_i
            }
          ]
        }
      end

      it 'updates the status of the corresponding message' do
        described_class.new(inbox: inbox, params: status_params).perform
        expect(message.reload.status).to eq('read')
      end

      it 'handles failed status with a reason' do
        failed_status_params = {
          'statuses' => [
            { 'id' => 'status_message_id', 'status' => 'failed', 'reason' => 'Message undeliverable' }
          ]
        }
        described_class.new(inbox: inbox, params: failed_status_params).perform
        message.reload
        expect(message.status).to eq('failed')
        expect(message.external_error).to eq('Message undeliverable')
      end

      it 'ignores statuses for non-existent messages' do
        non_existent_status_params = { 'statuses' => [{ 'id' => 'non_existent' }] }
        expect { described_class.new(inbox: inbox, params: non_existent_status_params).perform }
          .not_to raise_error
      end
    end

    context 'when fetching contact information' do
      let(:whapi_profile_response) do
        {
          'pushname' => 'John Doe Business',
          'icon_full' => 'https://example.com/avatar.jpg',
          'business_name' => 'Acme Corp',
          'about' => 'Available for business inquiries'
        }
      end

      let(:message_with_name) do
        {
          'messages' => [
            {
              'id' => 'msg_123',
              'from' => '1234567890',
              'from_name' => 'John Message Name',
              'type' => 'text',
              'text' => { 'body' => 'Hello' },
              'timestamp' => '1234567890'
            }
          ]
        }
      end

      before do
        allow(HTTParty).to receive(:get)
          .with('https://gate.whapi.cloud/contacts/1234567890/profile', any_args)
          .and_return(double(success?: true, parsed_response: whapi_profile_response))
      end

      it 'fetches contact information from WHAPI when contact has no avatar' do
        described_class.new(inbox: inbox, params: message_with_name).perform

        contact = Contact.find_by(phone_number: '+1234567890')
        expect(contact).to be_present
        expect(contact.name).to eq('John Doe Business') # Uses WHAPI name over message name
        expect(Avatar::AvatarFromUrlJob).to have_been_enqueued.with(contact, 'https://example.com/avatar.jpg')
        expect(contact.additional_attributes['business_name']).to eq('Acme Corp')
      end

      it 'does not fetch from WHAPI when contact already has avatar' do
        # Create contact with existing avatar
        contact = create(:contact, account: account, phone_number: '+1234567890', name: 'Existing Name')
        contact.avatar.attach(io: File.open('spec/assets/avatar.png'), filename: 'avatar.png')
        create(:contact_inbox, inbox: inbox, source_id: '1234567890', contact: contact)

        # Should not call WHAPI when contact already has avatar
        expect(HTTParty).not_to receive(:get)

        described_class.new(inbox: inbox, params: message_with_name).perform

        contact.reload
        expect(contact.name).to eq('Existing Name') # Should not update existing contact
        expect(Avatar::AvatarFromUrlJob).not_to have_been_enqueued
      end

      it 'falls back to message name when WHAPI contact fetch fails' do
        allow(HTTParty).to receive(:get)
          .with('https://gate.whapi.cloud/contacts/1234567890/profile', any_args)
          .and_return(double(success?: false, code: 404, body: 'Not found'))

        described_class.new(inbox: inbox, params: message_with_name).perform

        contact = Contact.find_by(phone_number: '+1234567890')
        expect(contact).to be_present
        expect(contact.name).to eq('John Message Name') # Falls back to message name
        expect(Avatar::AvatarFromUrlJob).not_to have_been_enqueued
      end

      it 'handles WHAPI response with no useful information' do
        allow(HTTParty).to receive(:get)
          .with('https://gate.whapi.cloud/contacts/1234567890/profile', any_args)
          .and_return(double(success?: true, parsed_response: {}))

        described_class.new(inbox: inbox, params: message_with_name).perform

        contact = Contact.find_by(phone_number: '+1234567890')
        expect(contact).to be_present
        expect(contact.name).to eq('John Message Name') # Uses message name when WHAPI has no name
        expect(Avatar::AvatarFromUrlJob).not_to have_been_enqueued
      end

      it 'updates contact with partial WHAPI information' do
        partial_response = {
          'pushname' => 'Updated Name'
          # No avatar or business name
        }

        allow(HTTParty).to receive(:get)
          .with('https://gate.whapi.cloud/contacts/1234567890/profile', any_args)
          .and_return(double(success?: true, parsed_response: partial_response))

        described_class.new(inbox: inbox, params: message_with_name).perform

        contact = Contact.find_by(phone_number: '+1234567890')
        expect(contact).to be_present
        expect(contact.name).to eq('Updated Name')
        expect(Avatar::AvatarFromUrlJob).not_to have_been_enqueued
        expect(contact.additional_attributes['business_name']).to be_nil
      end
    end
  end
end
