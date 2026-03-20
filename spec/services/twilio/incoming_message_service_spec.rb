require 'rails_helper'

describe Twilio::IncomingMessageService do
  let!(:account) { create(:account) }
  let!(:twilio_channel) do
    create(:channel_twilio_sms, account: account, account_sid: 'ACxxx',
                                inbox: create(:inbox, account: account, greeting_enabled: false))
  end
  let!(:contact) { create(:contact, account: account, phone_number: '+12345') }
  let(:contact_inbox) { create(:contact_inbox, source_id: '+12345', contact: contact, inbox: twilio_channel.inbox) }
  let!(:conversation) { create(:conversation, contact: contact, inbox: twilio_channel.inbox, contact_inbox: contact_inbox) }

  describe '#perform' do
    it 'creates a new message in existing conversation' do
      params = {
        SmsSid: 'SMxx',
        From: '+12345',
        AccountSid: 'ACxxx',
        MessagingServiceSid: twilio_channel.messaging_service_sid,
        Body: 'testing3'
      }

      described_class.new(params: params).perform
      expect(conversation.reload.messages.last.content).to eq('testing3')
    end

    it 'removes null bytes' do
      params = {
        SmsSid: 'SMxx',
        From: '+12345',
        AccountSid: 'ACxxx',
        MessagingServiceSid: twilio_channel.messaging_service_sid,
        Body: "remove\u0000 null bytes\u0000"
      }

      described_class.new(params: params).perform
      expect(conversation.reload.messages.last.content).to eq('remove null bytes')
    end

    it 'wont throw error when the body is empty' do
      params = {
        SmsSid: 'SMxx',
        From: '+12345',
        AccountSid: 'ACxxx',
        MessagingServiceSid: twilio_channel.messaging_service_sid
      }

      described_class.new(params: params).perform
      expect(conversation.reload.messages.last.content).to be_nil
    end

    it 'creates a new conversation when payload is from different number' do
      params = {
        SmsSid: 'SMxx',
        From: '+123456',
        AccountSid: 'ACxxx',
        MessagingServiceSid: twilio_channel.messaging_service_sid,
        Body: 'new conversation'
      }

      described_class.new(params: params).perform
      expect(twilio_channel.inbox.conversations.count).to eq(2)
    end

    # Since we support the case with phone number as well. the previous case is with accoud_sid and messaging_service_sid
    context 'with a phone number' do
      let!(:twilio_channel) do
        create(:channel_twilio_sms, :with_phone_number, account: account, account_sid: 'ACxxx',
                                                        inbox: create(:inbox, account: account, greeting_enabled: false))
      end

      it 'creates a new message in existing conversation' do
        params = {
          SmsSid: 'SMxx',
          From: '+12345',
          AccountSid: 'ACxxx',
          To: twilio_channel.phone_number,
          Body: 'testing3'
        }

        described_class.new(params: params).perform
        expect(conversation.reload.messages.last.content).to eq('testing3')
      end

      it 'creates a new conversation when payload is from different number' do
        params = {
          SmsSid: 'SMxx',
          From: '+123456',
          AccountSid: 'ACxxx',
          To: twilio_channel.phone_number,
          Body: 'new conversation'
        }

        described_class.new(params: params).perform
        expect(twilio_channel.inbox.conversations.count).to eq(2)
      end

      it 'reopen last conversation if last conversation is resolved and lock to single conversation is enabled' do
        params = {
          SmsSid: 'SMxx',
          From: '+12345',
          AccountSid: 'ACxxx',
          To: twilio_channel.phone_number,
          Body: 'testing3'
        }

        twilio_channel.inbox.update!(lock_to_single_conversation: true)
        conversation.update!(status: 'resolved')
        described_class.new(params: params).perform
        # message appended to the last conversation
        expect(conversation.reload.messages.last.content).to eq('testing3')
        expect(conversation.reload.status).to eq('open')
      end

      it 'creates a new conversation if last conversation is resolved and lock to single conversation is disabled' do
        params = {
          SmsSid: 'SMxx',
          From: '+12345',
          AccountSid: 'ACxxx',
          To: twilio_channel.phone_number,
          Body: 'testing3'
        }

        twilio_channel.inbox.update!(lock_to_single_conversation: false)
        conversation.update!(status: 'resolved')
        described_class.new(params: params).perform
        expect(twilio_channel.inbox.conversations.count).to eq(2)
        expect(twilio_channel.inbox.conversations.last.messages.last.content).to eq('testing3')
      end

      it 'will not create a new conversation if last conversation is not resolved and lock to single conversation is disabled' do
        params = {
          SmsSid: 'SMxx',
          From: '+12345',
          AccountSid: 'ACxxx',
          To: twilio_channel.phone_number,
          Body: 'testing3'
        }

        twilio_channel.inbox.update!(lock_to_single_conversation: false)
        conversation.update!(status: Conversation.statuses.except('resolved').keys.sample)
        described_class.new(params: params).perform
        expect(twilio_channel.inbox.conversations.count).to eq(1)
        expect(twilio_channel.inbox.conversations.last.messages.last.content).to eq('testing3')
      end
    end

    context 'with multiple channels configured' do
      before do
        2.times.each do
          create(:channel_twilio_sms, :with_phone_number, account: account, account_sid: 'ACxxx', messaging_service_sid: nil,
                                                          inbox: create(:inbox, account: account, greeting_enabled: false))
        end
      end

      it 'creates a new conversation in appropriate channel' do
        twilio_sms_channel = create(:channel_twilio_sms, :with_phone_number, account: account, account_sid: 'ACxxx',
                                                                             inbox: create(:inbox, account: account, greeting_enabled: false))

        params = {
          SmsSid: 'SMxx',
          From: '+123456',
          AccountSid: 'ACxxx',
          To: twilio_sms_channel.phone_number,
          Body: 'new conversation'
        }

        described_class.new(params: params).perform
        expect(twilio_sms_channel.inbox.conversations.count).to eq(1)
      end
    end

    context 'when a message with an attachment is received' do
      before do
        stub_request(:get, 'https://chatwoot-assets.local/sample.png')
          .to_return(status: 200, body: 'image data', headers: { 'Content-Type' => 'image/png' })
      end

      let(:params_with_attachment) do
        {
          SmsSid: 'SMxx',
          From: '+12345',
          AccountSid: 'ACxxx',
          MessagingServiceSid: twilio_channel.messaging_service_sid,
          Body: 'testing3',
          NumMedia: '1',
          MediaContentType0: 'image/jpeg',
          MediaUrl0: 'https://chatwoot-assets.local/sample.png'
        }
      end

      it 'creates a new message with media in existing conversation' do
        described_class.new(params: params_with_attachment).perform
        expect(conversation.reload.messages.last.content).to eq('testing3')
        expect(conversation.reload.messages.last.attachments.count).to eq(1)
        expect(conversation.reload.messages.last.attachments.first.file_type).to eq('image')
      end
    end

    context 'when there is an error downloading the attachment' do
      before do
        stub_request(:get, 'https://chatwoot-assets.local/sample.png')
          .to_raise(Down::Error.new('Download error'))

        stub_request(:get, 'https://chatwoot-assets.local/sample.png')
          .to_return(status: 200, body: 'image data', headers: { 'Content-Type' => 'image/png' })
      end

      let(:params_with_attachment_error) do
        {
          SmsSid: 'SMxx',
          From: '+12345',
          AccountSid: 'ACxxx',
          MessagingServiceSid: twilio_channel.messaging_service_sid,
          Body: 'testing3',
          NumMedia: '1',
          MediaContentType0: 'image/jpeg',
          MediaUrl0: 'https://chatwoot-assets.local/sample.png'
        }
      end

      it 'retries downloading the attachment without a token after an error' do
        expect do
          described_class.new(params: params_with_attachment_error).perform
        end.not_to raise_error

        expect(conversation.reload.messages.last.content).to eq('testing3')
        expect(conversation.reload.messages.last.attachments.count).to eq(1)
        expect(conversation.reload.messages.last.attachments.first.file_type).to eq('image')
      end
    end

    context 'when a message with multiple attachments is received' do
      before do
        stub_request(:get, 'https://chatwoot-assets.local/sample.png')
          .to_return(status: 200, body: 'image data 1', headers: { 'Content-Type' => 'image/png' })
        stub_request(:get, 'https://chatwoot-assets.local/sample.jpg')
          .to_return(status: 200, body: 'image data 2', headers: { 'Content-Type' => 'image/jpeg' })
      end

      let(:params_with_multiple_attachments) do
        {
          SmsSid: 'SMxx',
          From: '+12345',
          AccountSid: 'ACxxx',
          MessagingServiceSid: twilio_channel.messaging_service_sid,
          Body: 'testing multiple media',
          NumMedia: '2',
          MediaContentType0: 'image/png',
          MediaUrl0: 'https://chatwoot-assets.local/sample.png',
          MediaContentType1: 'image/jpeg',
          MediaUrl1: 'https://chatwoot-assets.local/sample.jpg'
        }
      end

      it 'creates a new message with multiple media attachments in existing conversation' do
        described_class.new(params: params_with_multiple_attachments).perform
        expect(conversation.reload.messages.last.content).to eq('testing multiple media')
        expect(conversation.reload.messages.last.attachments.count).to eq(2)
        expect(conversation.reload.messages.last.attachments.map(&:file_type)).to contain_exactly('image', 'image')
      end
    end

    context 'when a location message is received' do
      let(:params_with_location) do
        {
          SmsSid: 'SMxx',
          From: '+12345',
          AccountSid: 'ACxxx',
          MessagingServiceSid: twilio_channel.messaging_service_sid,
          MessageType: 'location',
          Latitude: '12.160894393921',
          Longitude: '75.265205383301'
        }
      end

      it 'creates a message with location attachment' do
        described_class.new(params: params_with_location).perform

        message = conversation.reload.messages.last
        expect(message.attachments.count).to eq(1)
        expect(message.attachments.first.file_type).to eq('location')
      end
    end

    context 'when ProfileName is provided for WhatsApp' do
      it 'uses ProfileName as contact name' do
        params = {
          SmsSid: 'SMxx',
          From: '+1234567890',
          AccountSid: 'ACxxx',
          MessagingServiceSid: twilio_channel.messaging_service_sid,
          Body: 'Hello with profile name',
          ProfileName: 'John Doe'
        }

        described_class.new(params: params).perform
        contact = twilio_channel.inbox.contacts.find_by(phone_number: '+1234567890')
        expect(contact.name).to eq('John Doe')
      end

      it 'falls back to formatted phone number when ProfileName is blank' do
        params = {
          SmsSid: 'SMxx',
          From: '+1234567890',
          AccountSid: 'ACxxx',
          MessagingServiceSid: twilio_channel.messaging_service_sid,
          Body: 'Hello without profile name',
          ProfileName: ''
        }

        described_class.new(params: params).perform
        contact = twilio_channel.inbox.contacts.find_by(phone_number: '+1234567890')
        expect(contact.name).to eq('1234567890')
      end

      it 'uses formatted phone number when ProfileName is not provided' do
        params = {
          SmsSid: 'SMxx',
          From: '+1234567890',
          AccountSid: 'ACxxx',
          MessagingServiceSid: twilio_channel.messaging_service_sid,
          Body: 'Regular SMS message'
        }

        described_class.new(params: params).perform
        contact = twilio_channel.inbox.contacts.find_by(phone_number: '+1234567890')
        expect(contact.name).to eq('1234567890')
      end

      it 'updates existing contact name when current name matches phone number' do
        # Create contact with phone number as name
        existing_contact = create(:contact,
                                  account: twilio_channel.inbox.account,
                                  name: '+1234567890',
                                  phone_number: '+1234567890')
        create(:contact_inbox,
               contact: existing_contact,
               inbox: twilio_channel.inbox,
               source_id: '+1234567890')

        params = {
          SmsSid: 'SMxx',
          From: '+1234567890',
          AccountSid: 'ACxxx',
          MessagingServiceSid: twilio_channel.messaging_service_sid,
          Body: 'Hello',
          ProfileName: 'Jane Smith'
        }

        described_class.new(params: params).perform
        existing_contact.reload
        expect(existing_contact.name).to eq('Jane Smith')
      end

      it 'does not update contact name when current name is different from phone number' do
        # Create contact with human name
        existing_contact = create(:contact,
                                  account: twilio_channel.inbox.account,
                                  name: 'John Doe',
                                  phone_number: '+1234567890')
        create(:contact_inbox,
               contact: existing_contact,
               inbox: twilio_channel.inbox,
               source_id: '+1234567890')

        params = {
          SmsSid: 'SMxx',
          From: '+1234567890',
          AccountSid: 'ACxxx',
          MessagingServiceSid: twilio_channel.messaging_service_sid,
          Body: 'Hello',
          ProfileName: 'Jane Smith'
        }

        described_class.new(params: params).perform
        existing_contact.reload
        expect(existing_contact.name).to eq('John Doe') # Should not change
      end

      it 'updates contact name when current name matches formatted phone number' do
        # Create contact with formatted phone number as name
        existing_contact = create(:contact,
                                  account: twilio_channel.inbox.account,
                                  name: '1234567890',
                                  phone_number: '+1234567890')
        create(:contact_inbox,
               contact: existing_contact,
               inbox: twilio_channel.inbox,
               source_id: '+1234567890')

        params = {
          SmsSid: 'SMxx',
          From: '+1234567890',
          AccountSid: 'ACxxx',
          MessagingServiceSid: twilio_channel.messaging_service_sid,
          Body: 'Hello',
          ProfileName: 'Alice Johnson'
        }

        described_class.new(params: params).perform
        existing_contact.reload
        expect(existing_contact.name).to eq('Alice Johnson')
      end

      describe 'When the incoming number is a Brazilian number in new format with 9 included' do
        let!(:whatsapp_twilio_channel) do
          create(:channel_twilio_sms, :whatsapp, account: account, account_sid: 'ACxxx',
                                                 inbox: create(:inbox, account: account, greeting_enabled: false))
        end

        it 'creates appropriate conversations, message and contacts if contact does not exist' do
          params = {
            SmsSid: 'SMxx',
            From: 'whatsapp:+5541988887777',
            AccountSid: 'ACxxx',
            MessagingServiceSid: whatsapp_twilio_channel.messaging_service_sid,
            Body: 'Test message from Brazil',
            ProfileName: 'João Silva'
          }

          described_class.new(params: params).perform

          expect(whatsapp_twilio_channel.inbox.conversations.count).not_to eq(0)
          expect(whatsapp_twilio_channel.inbox.contacts.first.name).to eq('João Silva')
          expect(whatsapp_twilio_channel.inbox.messages.first.content).to eq('Test message from Brazil')
          expect(whatsapp_twilio_channel.inbox.contact_inboxes.first.source_id).to eq('whatsapp:+5541988887777')
        end

        it 'appends to existing contact if contact inbox exists' do
          # Create existing contact with same format
          normalized_contact = create(:contact, account: account, phone_number: '+5541988887777')
          contact_inbox = create(:contact_inbox, source_id: 'whatsapp:+5541988887777', contact: normalized_contact,
                                                 inbox: whatsapp_twilio_channel.inbox)
          last_conversation = create(:conversation, inbox: whatsapp_twilio_channel.inbox, contact_inbox: contact_inbox)

          params = {
            SmsSid: 'SMxx',
            From: 'whatsapp:+5541988887777',
            AccountSid: 'ACxxx',
            MessagingServiceSid: whatsapp_twilio_channel.messaging_service_sid,
            Body: 'Another message from Brazil',
            ProfileName: 'João Silva'
          }

          described_class.new(params: params).perform

          # No new conversation should be created
          expect(whatsapp_twilio_channel.inbox.conversations.count).to eq(1)
          # Message appended to the last conversation
          expect(last_conversation.messages.last.content).to eq('Another message from Brazil')
        end
      end

      describe 'When incoming number is a Brazilian number in old format without the 9 included' do
        let!(:whatsapp_twilio_channel) do
          create(:channel_twilio_sms, :whatsapp, account: account, account_sid: 'ACxxx',
                                                 inbox: create(:inbox, account: account, greeting_enabled: false))
        end

        it 'appends to existing contact when contact inbox exists in old format' do
          # Create existing contact with old format (12 digits)
          old_contact = create(:contact, account: account, phone_number: '+554188887777')
          contact_inbox = create(:contact_inbox, source_id: 'whatsapp:+554188887777', contact: old_contact, inbox: whatsapp_twilio_channel.inbox)
          last_conversation = create(:conversation, inbox: whatsapp_twilio_channel.inbox, contact_inbox: contact_inbox)

          params = {
            SmsSid: 'SMxx',
            From: 'whatsapp:+554188887777',
            AccountSid: 'ACxxx',
            MessagingServiceSid: whatsapp_twilio_channel.messaging_service_sid,
            Body: 'Test message from Brazil old format',
            ProfileName: 'Maria Silva'
          }

          described_class.new(params: params).perform

          # No new conversation should be created
          expect(whatsapp_twilio_channel.inbox.conversations.count).to eq(1)
          # Message appended to the last conversation
          expect(last_conversation.messages.last.content).to eq('Test message from Brazil old format')
        end

        it 'appends to existing contact when contact inbox exists in new format' do
          # Create existing contact with new format (13 digits)
          normalized_contact = create(:contact, account: account, phone_number: '+5541988887777')
          contact_inbox = create(:contact_inbox, source_id: 'whatsapp:+5541988887777', contact: normalized_contact,
                                                 inbox: whatsapp_twilio_channel.inbox)
          last_conversation = create(:conversation, inbox: whatsapp_twilio_channel.inbox, contact_inbox: contact_inbox)

          # Incoming message with old format (12 digits)
          params = {
            SmsSid: 'SMxx',
            From: 'whatsapp:+554188887777',
            AccountSid: 'ACxxx',
            MessagingServiceSid: whatsapp_twilio_channel.messaging_service_sid,
            Body: 'Test message from Brazil',
            ProfileName: 'João Silva'
          }

          described_class.new(params: params).perform

          # Should find and use existing contact, not create duplicate
          expect(whatsapp_twilio_channel.inbox.conversations.count).to eq(1)
          # Message appended to the existing conversation
          expect(last_conversation.messages.last.content).to eq('Test message from Brazil')
          # Should use the existing contact's source_id (normalized format)
          expect(whatsapp_twilio_channel.inbox.contact_inboxes.first.source_id).to eq('whatsapp:+5541988887777')
        end

        it 'creates contact inbox with incoming number when no existing contact' do
          params = {
            SmsSid: 'SMxx',
            From: 'whatsapp:+554188887777',
            AccountSid: 'ACxxx',
            MessagingServiceSid: whatsapp_twilio_channel.messaging_service_sid,
            Body: 'Test message from Brazil',
            ProfileName: 'Carlos Silva'
          }

          described_class.new(params: params).perform

          expect(whatsapp_twilio_channel.inbox.conversations.count).not_to eq(0)
          expect(whatsapp_twilio_channel.inbox.contacts.first.name).to eq('Carlos Silva')
          expect(whatsapp_twilio_channel.inbox.messages.first.content).to eq('Test message from Brazil')
          expect(whatsapp_twilio_channel.inbox.contact_inboxes.first.source_id).to eq('whatsapp:+554188887777')
        end
      end

      describe 'When the incoming number is an Argentine number with 9 after country code' do
        let!(:whatsapp_twilio_channel) do
          create(:channel_twilio_sms, :whatsapp, account: account, account_sid: 'ACxxx',
                                                 inbox: create(:inbox, account: account, greeting_enabled: false))
        end

        it 'creates appropriate conversations, message and contacts if contact does not exist' do
          params = {
            SmsSid: 'SMxx',
            From: 'whatsapp:+5491123456789',
            AccountSid: 'ACxxx',
            MessagingServiceSid: whatsapp_twilio_channel.messaging_service_sid,
            Body: 'Test message from Argentina',
            ProfileName: 'Carlos Mendoza'
          }

          described_class.new(params: params).perform

          expect(whatsapp_twilio_channel.inbox.conversations.count).not_to eq(0)
          expect(whatsapp_twilio_channel.inbox.contacts.first.name).to eq('Carlos Mendoza')
          expect(whatsapp_twilio_channel.inbox.messages.first.content).to eq('Test message from Argentina')
          expect(whatsapp_twilio_channel.inbox.contact_inboxes.first.source_id).to eq('whatsapp:+5491123456789')
        end

        it 'appends to existing contact if contact inbox exists with normalized format' do
          # Create existing contact with normalized format (without 9 after country code)
          normalized_contact = create(:contact, account: account, phone_number: '+541123456789')
          contact_inbox = create(:contact_inbox, source_id: 'whatsapp:+541123456789', contact: normalized_contact,
                                                 inbox: whatsapp_twilio_channel.inbox)
          last_conversation = create(:conversation, inbox: whatsapp_twilio_channel.inbox, contact_inbox: contact_inbox)

          # Incoming message with 9 after country code
          params = {
            SmsSid: 'SMxx',
            From: 'whatsapp:+5491123456789',
            AccountSid: 'ACxxx',
            MessagingServiceSid: whatsapp_twilio_channel.messaging_service_sid,
            Body: 'Test message from Argentina',
            ProfileName: 'Carlos Mendoza'
          }

          described_class.new(params: params).perform

          # Should find and use existing contact, not create duplicate
          expect(whatsapp_twilio_channel.inbox.conversations.count).to eq(1)
          # Message appended to the existing conversation
          expect(last_conversation.messages.last.content).to eq('Test message from Argentina')
          # Should use the normalized source_id from existing contact
          expect(whatsapp_twilio_channel.inbox.contact_inboxes.first.source_id).to eq('whatsapp:+541123456789')
        end
      end

      describe 'When incoming number is an Argentine number without 9 after country code' do
        let!(:whatsapp_twilio_channel) do
          create(:channel_twilio_sms, :whatsapp, account: account, account_sid: 'ACxxx',
                                                 inbox: create(:inbox, account: account, greeting_enabled: false))
        end

        it 'appends to existing contact when contact inbox exists with same format' do
          # Create existing contact with same format (without 9)
          contact = create(:contact, account: account, phone_number: '+541123456789')
          contact_inbox = create(:contact_inbox, source_id: 'whatsapp:+541123456789', contact: contact, inbox: whatsapp_twilio_channel.inbox)
          last_conversation = create(:conversation, inbox: whatsapp_twilio_channel.inbox, contact_inbox: contact_inbox)

          params = {
            SmsSid: 'SMxx',
            From: 'whatsapp:+541123456789',
            AccountSid: 'ACxxx',
            MessagingServiceSid: whatsapp_twilio_channel.messaging_service_sid,
            Body: 'Test message from Argentina',
            ProfileName: 'Ana García'
          }

          described_class.new(params: params).perform

          # No new conversation should be created
          expect(whatsapp_twilio_channel.inbox.conversations.count).to eq(1)
          # Message appended to the last conversation
          expect(last_conversation.messages.last.content).to eq('Test message from Argentina')
        end

        it 'creates contact inbox with incoming number when no existing contact' do
          params = {
            SmsSid: 'SMxx',
            From: 'whatsapp:+541123456789',
            AccountSid: 'ACxxx',
            MessagingServiceSid: whatsapp_twilio_channel.messaging_service_sid,
            Body: 'Test message from Argentina',
            ProfileName: 'Diego López'
          }

          described_class.new(params: params).perform

          expect(whatsapp_twilio_channel.inbox.conversations.count).not_to eq(0)
          expect(whatsapp_twilio_channel.inbox.contacts.first.name).to eq('Diego López')
          expect(whatsapp_twilio_channel.inbox.messages.first.content).to eq('Test message from Argentina')
          expect(whatsapp_twilio_channel.inbox.contact_inboxes.first.source_id).to eq('whatsapp:+541123456789')
        end
      end
    end
  end
end
