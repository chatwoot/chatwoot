require 'rails_helper'

describe Whatsapp::ZapiHandlers::ReceivedCallback do
  let!(:whatsapp_channel) do
    create(:channel_whatsapp, provider: 'zapi', validate_provider_config: false)
  end
  let(:inbox) { whatsapp_channel.inbox }
  let(:service) { Whatsapp::IncomingMessageZapiService.new(inbox: inbox, params: params) }

  describe '#set_contact with LID handling' do
    let(:base_params) do
      {
        type: 'ReceivedCallback',
        messageId: 'msg_123',
        momment: Time.current.to_i * 1000,
        fromMe: false,
        chatName: 'John Doe',
        text: { message: 'Hello' }
      }
    end

    context 'when creating a new contact' do
      context 'with LID only (no phone number available)' do
        let(:params) do
          base_params.merge(
            phone: '123456789@lid',
            chatLid: '123456789@lid'
          )
        end

        it 'creates contact with identifier but no phone_number' do
          expect do
            service.perform
          end.to change(Contact, :count).by(1)

          contact = Contact.last
          expect(contact.identifier).to eq('123456789@lid')
          expect(contact.phone_number).to be_nil
          expect(contact.name).to eq('John Doe')
        end

        it 'creates contact_inbox with correct source_id' do
          service.perform

          contact_inbox = ContactInbox.last
          expect(contact_inbox.source_id).to eq('123456789')
        end
      end

      context 'with both phone number and LID' do
        let(:params) do
          base_params.merge(
            phone: '5511987654321',
            chatLid: '123456789@lid'
          )
        end

        it 'creates contact with both identifier and phone_number' do
          expect do
            service.perform
          end.to change(Contact, :count).by(1)

          contact = Contact.last
          expect(contact.identifier).to eq('123456789@lid')
          expect(contact.phone_number).to eq('+5511987654321')
          expect(contact.name).to eq('John Doe')
        end

        it 'creates contact_inbox with LID as source_id' do
          service.perform

          contact_inbox = ContactInbox.last
          expect(contact_inbox.source_id).to eq('123456789')
        end
      end

      context 'when phone matches chatLid (both are LID)' do
        let(:params) do
          base_params.merge(
            phone: '123456789@lid',
            chatLid: '123456789@lid'
          )
        end

        it 'creates contact with identifier but no phone_number' do
          service.perform

          contact = Contact.last
          expect(contact.identifier).to eq('123456789@lid')
          expect(contact.phone_number).to be_nil
        end
      end
    end

    context 'when updating an existing contact' do
      context 'when contact is created with LID only, now receives actual phone number' do
        let!(:existing_contact) do
          create(:contact,
                 account: inbox.account,
                 identifier: '123456789@lid',
                 phone_number: nil,
                 name: 'John Doe')
        end
        let!(:existing_contact_inbox) do
          create(:contact_inbox,
                 inbox: inbox,
                 contact: existing_contact,
                 source_id: '123456789')
        end
        let(:params) do
          base_params.merge(
            phone: '5511987654321',
            chatLid: '123456789@lid'
          )
        end

        it 'reuses existing contact and does not create a new one' do
          expect do
            service.perform
          end.not_to change(Contact, :count)
        end

        it 'reuses existing contact_inbox' do
          expect do
            service.perform
          end.not_to change(ContactInbox, :count)

          expect(ContactInbox.last.id).to eq(existing_contact_inbox.id)
        end

        it 'updates the contact phone_number when it becomes available' do
          service.perform

          expect(existing_contact.reload.phone_number).to eq('+5511987654321')
        end

        it 'creates message for the conversation' do
          expect do
            service.perform
          end.to change(Message, :count).by(1)

          message = Message.last
          expect(message.sender).to eq(existing_contact)
        end

        it 'does not overwrite phone_number if contact already has one' do
          existing_contact.update!(phone_number: '+5511999999999')

          service.perform

          expect(existing_contact.reload.phone_number).to eq('+5511999999999')
        end
      end

      context 'when contact is created with phone number, now receives LID' do
        let!(:existing_contact) do
          create(:contact,
                 account: inbox.account,
                 identifier: nil,
                 phone_number: '+5511987654321',
                 name: 'John Doe')
        end
        let!(:existing_contact_inbox) do
          create(:contact_inbox,
                 inbox: inbox,
                 contact: existing_contact,
                 source_id: '5511987654321')
        end
        let(:params) do
          base_params.merge(
            phone: '123456789@lid',
            chatLid: '123456789@lid'
          )
        end

        it 'creates a new contact with LID identifier' do
          # ContactInboxWithContactBuilder will not find by source_id (different)
          # Will not find by identifier (nil)
          # Will not find by phone_number (param has no phone_number)
          # So it creates a new contact
          expect do
            service.perform
          end.to change(Contact, :count).by(1)

          new_contact = Contact.last
          expect(new_contact.identifier).to eq('123456789@lid')
          expect(new_contact.phone_number).to be_nil
          expect(new_contact).not_to eq(existing_contact)
        end

        it 'creates a new contact_inbox with new source_id' do
          expect do
            service.perform
          end.to change(ContactInbox, :count).by(1)

          new_contact_inbox = ContactInbox.last
          expect(new_contact_inbox.source_id).to eq('123456789')
          expect(new_contact_inbox).not_to eq(existing_contact_inbox)
        end
      end

      context 'when contact exists with identifier and no phone, receives same LID' do
        let!(:existing_contact) do
          create(:contact,
                 account: inbox.account,
                 identifier: '123456789@lid',
                 phone_number: nil,
                 name: 'John Doe')
        end
        let(:params) do
          base_params.merge(
            phone: '123456789@lid',
            chatLid: '123456789@lid'
          )
        end

        before do
          create(:contact_inbox,
                 inbox: inbox,
                 contact: existing_contact,
                 source_id: '123456789')
        end

        it 'reuses existing contact' do
          expect do
            service.perform
          end.not_to change(Contact, :count)
        end

        it 'reuses existing contact_inbox' do
          expect do
            service.perform
          end.not_to change(ContactInbox, :count)
        end
      end

      context 'when updating contact name when name is raw phone number' do
        let!(:existing_contact) do
          create(:contact,
                 account: inbox.account,
                 identifier: '123456789@lid',
                 phone_number: nil,
                 name: '5511987654321')
        end
        let(:params) do
          base_params.merge(
            phone: '5511987654321',
            chatLid: '123456789@lid',
            chatName: 'John Updated'
          )
        end

        before do
          create(:contact_inbox,
                 inbox: inbox,
                 contact: existing_contact,
                 source_id: '123456789')
        end

        it 'updates contact name when it matches raw phone' do
          service.perform

          expect(existing_contact.reload.name).to eq('John Updated')
        end
      end

      context 'when updating contact name when name is LID' do
        let!(:existing_contact) do
          create(:contact,
                 account: inbox.account,
                 identifier: '123456789@lid',
                 phone_number: nil,
                 name: '123456789@lid')
        end
        let(:params) do
          base_params.merge(
            phone: '123456789@lid',
            chatLid: '123456789@lid',
            chatName: 'John Updated'
          )
        end

        before do
          create(:contact_inbox,
                 inbox: inbox,
                 contact: existing_contact,
                 source_id: '123456789')
        end

        it 'updates contact name when it matches the phone value' do
          service.perform

          expect(existing_contact.reload.name).to eq('John Updated')
        end
      end
    end

    context 'when handling contact name' do
      let(:params_with_lid) do
        base_params.merge(
          phone: '123456789@lid',
          chatLid: '123456789@lid'
        )
      end

      context 'when senderName is present' do
        let(:params) { params_with_lid.merge(senderName: 'John Sender', chatName: 'John from Chat') }

        it 'uses senderName as contact name (higher priority)' do
          service.perform

          contact = Contact.last
          expect(contact.name).to eq('John Sender')
        end
      end

      context 'when senderName is absent but chatName is present' do
        let(:params) { params_with_lid.merge(senderName: nil, chatName: 'John from Chat') }

        it 'uses chatName as contact name' do
          service.perform

          contact = Contact.last
          expect(contact.name).to eq('John from Chat')
        end
      end

      context 'when both senderName and chatName are absent' do
        let(:params) { params_with_lid.merge(senderName: nil, chatName: nil) }

        it 'uses phone as contact name' do
          service.perform

          contact = Contact.last
          expect(contact.name).to eq('123456789@lid')
        end
      end
    end

    context 'when contact exists by phone but new LID provided' do
      let!(:existing_contact) do
        create(:contact,
               account: inbox.account,
               identifier: '999999999@lid',
               phone_number: '+5511987654321',
               name: 'Existing Contact')
      end
      let(:params) do
        base_params.merge(
          phone: '5511987654321',
          chatLid: '123456789@lid'
        )
      end

      before do
        create(:contact_inbox,
               inbox: inbox,
               contact: existing_contact,
               source_id: '999999999')
      end

      it 'finds existing contact by phone_number' do
        expect do
          service.perform
        end.not_to change(Contact, :count)
      end

      it 'updates existing contact_inbox with new source_id' do
        expect do
          service.perform
        end.not_to change(ContactInbox, :count)

        existing_contact_inbox = existing_contact.contact_inboxes.find_by(inbox: inbox)
        expect(existing_contact_inbox.source_id).to eq('123456789')
      end
    end

    context 'when contact_inbox exists with phone as source_id (manual creation)' do
      let!(:existing_contact) do
        create(:contact,
               account: inbox.account,
               identifier: nil,
               phone_number: '+5511987654321',
               name: 'Manually Created Contact')
      end
      let!(:existing_contact_inbox) do
        create(:contact_inbox,
               inbox: inbox,
               contact: existing_contact,
               source_id: '5511987654321')
      end
      let(:params) do
        base_params.merge(
          phone: '5511987654321',
          chatLid: '123456789@lid'
        )
      end

      it 'updates existing contact_inbox source_id from phone to LID' do
        service.perform

        expect(existing_contact_inbox.reload.source_id).to eq('123456789')
      end

      it 'updates existing contact identifier with LID' do
        service.perform

        expect(existing_contact.reload.identifier).to eq('123456789@lid')
      end

      it 'does not create a new contact_inbox' do
        expect do
          service.perform
        end.not_to change(ContactInbox, :count)
      end

      it 'does not create a new contact' do
        expect do
          service.perform
        end.not_to change(Contact, :count)
      end

      it 'reuses the existing contact for message' do
        service.perform

        message = Message.last
        expect(message.sender).to eq(existing_contact)
      end
    end

    context 'when handling avatar' do
      let(:params) do
        base_params.merge(
          phone: '123456789@lid',
          chatLid: '123456789@lid',
          senderPhoto: 'https://example.com/avatar.jpg'
        )
      end

      it 'enqueues avatar update job when senderPhoto is present' do
        expect(Avatar::AvatarFromUrlJob).to receive(:perform_later)
          .with(kind_of(Contact), 'https://example.com/avatar.jpg')

        service.perform
      end

      it 'does not enqueue avatar update job when senderPhoto is missing' do
        params[:senderPhoto] = nil

        expect(Avatar::AvatarFromUrlJob).not_to receive(:perform_later)

        service.perform
      end

      it 'uses photo field as fallback when senderPhoto is not present' do
        params[:senderPhoto] = nil
        params[:photo] = 'https://example.com/photo.jpg'

        expect(Avatar::AvatarFromUrlJob).to receive(:perform_later)
          .with(kind_of(Contact), 'https://example.com/photo.jpg')

        service.perform
      end

      it 'does not enqueue job when URL is invalid' do
        params[:senderPhoto] = 'not-a-url'

        expect(Avatar::AvatarFromUrlJob).not_to receive(:perform_later)

        service.perform
      end
    end

    describe 'conversation duplication after deletion or resolution' do
      let(:phone) { '5511912345678' }
      let(:lid) { '12345678' }

      def build_params(message_id:, text:)
        {
          type: 'ReceivedCallback',
          messageId: message_id,
          momment: Time.current.to_i * 1000,
          fromMe: false,
          phone: phone,
          chatLid: "#{lid}@lid",
          chatName: 'John Doe',
          text: { message: text }
        }
      end

      shared_examples 'routes messages to the new conversation' do |first_msg_id:, second_msg_id:|
        it 'routes incoming messages to the new conversation, not a third one' do
          # Step 1: Create contact and first contact_inbox with phone as source_id
          contact = create(:contact, account: inbox.account, phone_number: "+#{phone}", identifier: nil)
          first_contact_inbox = create(:contact_inbox, inbox: inbox, contact: contact, source_id: phone)
          first_conversation = create(:conversation, inbox: inbox, contact: contact, contact_inbox: first_contact_inbox)

          # Step 2: Contact responds - this updates contact_inbox source_id from phone to LID
          Whatsapp::IncomingMessageZapiService.new(
            inbox: inbox,
            params: build_params(message_id: first_msg_id, text: 'First response')
          ).perform

          # Verify message landed in first conversation and source_id migrated
          expect(first_conversation.messages.count).to eq(1)
          expect(first_contact_inbox.reload.source_id).to eq(lid)

          # Step 3: Either delete or resolve the first conversation
          close_first_conversation.call(first_conversation)

          # Step 4: Create a new conversation (simulating UI creating a new contact_inbox)
          second_contact_inbox = create(:contact_inbox, inbox: inbox, contact: contact, source_id: phone)
          second_conversation = create(:conversation, inbox: inbox, contact: contact, contact_inbox: second_contact_inbox, status: :open)
          expect(inbox.contact_inboxes.where(contact: contact).count).to eq(2)

          # Step 5: Contact responds again - should NOT create a third conversation
          expect do
            Whatsapp::IncomingMessageZapiService.new(
              inbox: inbox,
              params: build_params(message_id: second_msg_id, text: 'Second response')
            ).perform
          end.not_to change(Conversation, :count)

          # The message should arrive in the second conversation
          expect(second_conversation.reload.messages.last.content).to eq('Second response')

          # The duplicate contact_inboxes should be consolidated
          expect(inbox.contact_inboxes.where(contact: contact).count).to eq(1)
        end
      end

      context 'when a conversation is deleted and a new one is created for the same contact' do
        let(:close_first_conversation) { ->(conv) { conv.destroy! } }

        it_behaves_like 'routes messages to the new conversation', first_msg_id: 'msg_001', second_msg_id: 'msg_002'
      end

      context 'when a conversation is resolved and a new one is created for the same contact' do
        let(:close_first_conversation) { ->(conv) { conv.update!(status: :resolved) } }

        it_behaves_like 'routes messages to the new conversation', first_msg_id: 'msg_003', second_msg_id: 'msg_004'
      end
    end

    describe 'single conversation mode' do
      let(:phone) { '5511912345678' }
      let(:lid) { '12345678' }

      before { inbox.update!(lock_to_single_conversation: true) }

      def build_params(message_id:, text:)
        {
          type: 'ReceivedCallback',
          messageId: message_id,
          momment: Time.current.to_i * 1000,
          fromMe: false,
          phone: phone,
          chatLid: "#{lid}@lid",
          chatName: 'John Doe',
          text: { message: text }
        }
      end

      it 'reopens resolved conversation when contact sends new message' do
        Whatsapp::IncomingMessageZapiService.new(inbox: inbox, params: build_params(message_id: 'msg_1', text: 'First')).perform
        conversation = Conversation.last
        conversation.update!(status: :resolved)

        expect { Whatsapp::IncomingMessageZapiService.new(inbox: inbox, params: build_params(message_id: 'msg_2', text: 'Second')).perform }
          .not_to change(Conversation, :count)

        expect(conversation.reload.status).to eq('open')
      end

      it 'migrates phone source_id to LID and routes to existing conversation' do
        contact = create(:contact, account: inbox.account, phone_number: "+#{phone}")
        contact_inbox = create(:contact_inbox, inbox: inbox, contact: contact, source_id: phone)
        conversation = create(:conversation, inbox: inbox, contact: contact, contact_inbox: contact_inbox)

        Whatsapp::IncomingMessageZapiService.new(inbox: inbox, params: build_params(message_id: 'msg_3', text: 'Response')).perform

        expect(contact_inbox.reload.source_id).to eq(lid)
        expect(conversation.messages.count).to eq(1)
      end

      it 'finds conversation via ConversationBuilder when agent creates new contact_inbox with phone' do
        Whatsapp::IncomingMessageZapiService.new(inbox: inbox, params: build_params(message_id: 'msg_4', text: 'Hello')).perform
        first_conversation = Conversation.last
        first_conversation.update!(status: :resolved)

        contact = Contact.last
        phone_contact_inbox = ContactInboxBuilder.new(contact: contact, inbox: inbox, source_id: nil).perform

        conversation = ConversationBuilder.new(params: ActionController::Parameters.new({}), contact_inbox: phone_contact_inbox).perform

        expect(conversation.id).to eq(first_conversation.id)
      end
    end
  end

  describe '#process_received_callback' do
    let(:contact_phone) { '+5511987654321' }
    let(:message_id) { 'msg_123' }
    let(:contact) { create(:contact, phone_number: contact_phone, account: inbox.account) }
    let(:params) do
      {
        type: 'ReceivedCallback',
        messageId: message_id,
        momment: Time.current.to_i * 1000,
        phone: '5511987654321',
        chatLid: '5511987654321',
        fromMe: false,
        text: { message: 'Hello World' }
      }
    end

    it 'creates a new message when message does not exist' do
      expect do
        service.perform
      end.to change(Message, :count).by(1)

      message = Message.last
      expect(message.content).to eq('Hello World')
      expect(message.source_id).to eq(message_id)
      expect(message.message_type).to eq('incoming')
    end

    it 'does not create duplicate messages' do
      service.perform

      expect do
        service.perform
      end.not_to change(Message, :count)
    end

    it 'does not process messages with notification key' do
      notification_params = params.merge(notification: 'REVOKE')

      expect do
        Whatsapp::IncomingMessageZapiService.new(inbox: inbox, params: notification_params).perform
      end.not_to change(Message, :count)
    end

    it 'handles edited messages' do
      service.perform
      original_message = Message.last
      edited_params = params.merge(
        isEdit: true,
        text: { message: 'Hello World - Edited' }
      )

      Whatsapp::IncomingMessageZapiService.new(inbox: inbox, params: edited_params).perform

      expect(original_message.reload.content).to eq('Hello World - Edited')
      expect(original_message.content_attributes['is_edited']).to be(true)
      expect(original_message.content_attributes['previous_content']).to eq('Hello World')
    end

    it 'calls channel received_messages method for incoming messages' do
      allow(inbox.channel).to receive(:received_messages)
      service.perform

      message = Message.last
      conversation = message.conversation
      expect(inbox.channel).to have_received(:received_messages).with([message], conversation)
    end

    context 'when processing image message' do
      let(:params) do
        {
          type: 'ReceivedCallback',
          messageId: 'img_123',
          momment: Time.current.to_i * 1000,
          phone: '5511987654321',
          chatLid: '5511987654321',
          fromMe: false,
          image: {
            caption: 'Check this image',
            imageUrl: 'https://example.com/image.jpg',
            mimeType: 'image/jpeg'
          }
        }
      end

      before do
        stub_request(:get, 'https://example.com/image.jpg')
          .to_return(status: 200, body: 'fake image data', headers: { 'Content-Type' => 'image/jpeg' })
      end

      it 'creates message with image attachment' do
        expect do
          service.perform
        end.to change(Message, :count).by(1)

        message = Message.last
        expect(message.content).to eq('Check this image')
        expect(message.attachments.count).to eq(1)
        expect(message.attachments.first.file_type).to eq('image')
      end
    end

    context 'when processing audio message' do
      let(:params) do
        {
          type: 'ReceivedCallback',
          messageId: 'audio_123',
          momment: Time.current.to_i * 1000,
          phone: '5511987654321',
          chatLid: '5511987654321',
          fromMe: false,
          audio: {
            audioUrl: 'https://example.com/audio.mp3',
            mimeType: 'audio/mpeg'
          }
        }
      end

      before do
        stub_request(:get, 'https://example.com/audio.mp3')
          .to_return(status: 200, body: 'fake audio data', headers: { 'Content-Type' => 'audio/mpeg' })
      end

      it 'creates message with audio attachment' do
        expect do
          service.perform
        end.to change(Message, :count).by(1)

        message = Message.last
        expect(message.attachments.count).to eq(1)
        expect(message.attachments.first.file_type).to eq('audio')
      end
    end

    context 'when processing video message' do
      let(:params) do
        {
          type: 'ReceivedCallback',
          messageId: 'video_123',
          momment: Time.current.to_i * 1000,
          phone: '5511987654321',
          chatLid: '5511987654321',
          fromMe: false,
          video: {
            caption: 'Check this video',
            videoUrl: 'https://example.com/video.mp4',
            mimeType: 'video/mp4'
          }
        }
      end

      before do
        stub_request(:get, 'https://example.com/video.mp4')
          .to_return(status: 200, body: 'fake video data', headers: { 'Content-Type' => 'video/mp4' })
      end

      it 'creates message with video attachment' do
        expect do
          service.perform
        end.to change(Message, :count).by(1)

        message = Message.last
        expect(message.content).to eq('Check this video')
        expect(message.attachments.count).to eq(1)
        expect(message.attachments.first.file_type).to eq('video')
      end
    end

    context 'when processing document message' do
      let(:params) do
        {
          type: 'ReceivedCallback',
          messageId: 'doc_123',
          momment: Time.current.to_i * 1000,
          phone: '5511987654321',
          chatLid: '5511987654321',
          fromMe: false,
          document: {
            documentUrl: 'https://example.com/document.pdf',
            fileName: 'document.pdf',
            mimeType: 'application/pdf'
          }
        }
      end

      before do
        stub_request(:get, 'https://example.com/document.pdf')
          .to_return(status: 200, body: 'fake pdf data', headers: { 'Content-Type' => 'application/pdf' })
      end

      it 'creates message with document attachment' do
        expect do
          service.perform
        end.to change(Message, :count).by(1)

        message = Message.last
        expect(message.content).to eq('document.pdf')
        expect(message.attachments.count).to eq(1)
        expect(message.attachments.first.file_type).to eq('file')
      end
    end

    context 'when processing unsupported message type' do
      let(:params) do
        {
          type: 'ReceivedCallback',
          messageId: 'unsupported_123',
          momment: Time.current.to_i * 1000,
          phone: '5511987654321',
          chatLid: '5511987654321',
          fromMe: false,
          data: 'some unsupported data'
        }
      end

      it 'creates message marked as unsupported' do
        expect do
          service.perform
        end.to change(Message, :count).by(1)

        message = Message.last
        expect(message.content).to be_blank
        expect(message.is_unsupported).to be(true)
      end
    end

    context 'when processing reaction message' do
      let(:contact_inbox) { create(:contact_inbox, inbox: inbox, contact: contact, source_id: '5511987654321') }
      let(:conversation) { create(:conversation, inbox: inbox, contact_inbox: contact_inbox) }
      let(:params) do
        {
          type: 'ReceivedCallback',
          messageId: 'reaction_123',
          momment: Time.current.to_i * 1000,
          phone: '5511987654321',
          chatLid: '5511987654321',
          fromMe: false,
          reaction: {
            value: '👍',
            referencedMessage: { messageId: 'original_123' }
          }
        }
      end

      before do
        create(:message, inbox: inbox, conversation: conversation, source_id: 'original_123')
      end

      it 'creates reaction message' do
        expect do
          service.perform
        end.to change(Message, :count).by(1)

        message = Message.last
        expect(message.content).to eq('👍')
        expect(message.content_attributes[:is_reaction]).to be(true)
        expect(message.content_attributes[:in_reply_to_external_id]).to eq('original_123')
      end

      it 'creates empty reaction message' do
        params[:reaction][:value] = ''

        expect do
          service.perform
        end.to change(Message, :count).by(1)

        message = Message.last
        expect(message.content).to eq('')
        expect(message.content_attributes[:is_reaction]).to be(true)
      end
    end

    context 'when processing sticker message' do
      let(:params) do
        {
          type: 'ReceivedCallback',
          messageId: 'sticker_123',
          momment: Time.current.to_i * 1000,
          phone: '5511987654321',
          chatLid: '5511987654321',
          fromMe: false,
          sticker: {
            stickerUrl: 'https://example.com/sticker.webp',
            mimeType: 'image/webp'
          }
        }
      end

      before do
        stub_request(:get, 'https://example.com/sticker.webp')
          .to_return(status: 200, body: 'fake sticker data', headers: { 'Content-Type' => 'image/webp' })
      end

      it 'creates message with sticker attachment' do
        expect do
          service.perform
        end.to change(Message, :count).by(1)

        message = Message.last
        expect(message.attachments.count).to eq(1)
        expect(message.attachments.first.file_type).to eq('image')
      end
    end

    context 'when processing outgoing message' do
      let(:params) do
        {
          type: 'ReceivedCallback',
          messageId: 'outgoing_123',
          momment: Time.current.to_i * 1000,
          phone: '5511987654321',
          chatLid: '5511987654321',
          fromMe: true,
          text: { message: 'Outgoing message' }
        }
      end

      before do
        create(:account_user, account: inbox.account)
      end

      it 'creates outgoing message' do
        expect do
          service.perform
        end.to change(Message, :count).by(1)

        message = Message.last
        expect(message.content).to eq('Outgoing message')
        expect(message.message_type).to eq('outgoing')
      end

      it 'does not call channel received_messages method for outgoing messages' do
        allow(inbox.channel).to receive(:received_messages)

        service.perform

        expect(inbox.channel).not_to have_received(:received_messages)
      end
    end

    context 'when handling duplicated events' do
      let(:params) do
        {
          type: 'ReceivedCallback',
          messageId: 'duplicate_123',
          momment: Time.current.to_i * 1000,
          phone: '5511987654321',
          chatLid: '5511987654321',
          fromMe: false,
          text: { message: 'Duplicated event' }
        }
      end

      it 'does not create message if it is already being processed' do
        # Simulate lock already acquired by returning false from SETNX
        allow(Redis::Alfred).to receive(:set)
          .with(format_message_source_key('duplicate_123'), true, nx: true, ex: 1.day)
          .and_return(false)

        expect do
          service.perform
        end.not_to change(Message, :count)
      end

      it 'caches and clears message source id in Redis' do
        allow(Redis::Alfred).to receive(:set).and_return(true)
        allow(Redis::Alfred).to receive(:delete)

        service.perform

        expect(Redis::Alfred).to have_received(:set)
          .with(format_message_source_key('duplicate_123'), true, nx: true, ex: 1.day)
        expect(Redis::Alfred).to have_received(:delete)
          .with(format_message_source_key('duplicate_123'))
      end

      it 'does not clear lock when acquisition fails' do
        allow(Redis::Alfred).to receive(:set)
          .with(format_message_source_key('duplicate_123'), true, nx: true, ex: 1.day)
          .and_return(false)
        allow(Redis::Alfred).to receive(:delete)

        service.perform

        expect(Redis::Alfred).not_to have_received(:delete)
          .with(format_message_source_key('duplicate_123'))
      end
    end

    context 'when attachment download fails' do
      let(:params) do
        {
          type: 'ReceivedCallback',
          messageId: 'img_fail_123',
          momment: Time.current.to_i * 1000,
          phone: '5511987654321',
          chatLid: '5511987654321',
          fromMe: false,
          image: {
            caption: 'Failed image',
            imageUrl: 'https://example.com/broken.jpg',
            mimeType: 'image/jpeg'
          }
        }
      end

      before do
        allow(Down).to receive(:download).and_raise(Down::ResponseError.new('Download failed'))
        allow(Rails.logger).to receive(:error)
      end

      it 'creates message marked as unsupported when download fails' do
        expect do
          service.perform
        end.to change(Message, :count).by(1)

        message = Message.last
        expect(message.is_unsupported).to be(true)
        expect(Rails.logger).to have_received(:error).with(/Failed to download attachment/)
      end

      it 'handles malformed attachment URLs gracefully' do
        allow(Down).to receive(:download).and_raise(Down::InvalidUrl.new('Invalid URL'))

        expect do
          service.perform
        end.to change(Message, :count).by(1)

        message = Message.last
        expect(message.is_unsupported).to be(true)
      end

      it 'handles network timeout errors' do
        allow(Down).to receive(:download).and_raise(Down::TimeoutError.new('Download timeout'))

        expect do
          service.perform
        end.to change(Message, :count).by(1)

        message = Message.last
        expect(message.is_unsupported).to be(true)
      end
    end

    context 'when contact name handling' do
      let(:params) do
        {
          type: 'ReceivedCallback',
          messageId: 'name_123',
          momment: Time.current.to_i * 1000,
          phone: '5511987654322',
          chatLid: '5511987654322',
          fromMe: false,
          senderName: 'John Doe from Z-API',
          text: { message: 'Hello with name' }
        }
      end

      it 'creates contact with sender name when provided' do
        service.perform

        contact = Contact.last
        expect(contact.name).to eq('John Doe from Z-API')
      end

      it 'uses phone number as name when sender name is not provided' do
        params.delete(:senderName)

        service.perform

        message = Message.last
        expect(message.sender.name).to eq('5511987654322')
      end
    end

    context 'when message should not be processed' do
      let(:params) do
        {
          type: 'ReceivedCallback',
          messageId: 'filtered_123',
          momment: Time.current.to_i * 1000,
          phone: '5511987654321',
          chatLid: '5511987654321',
          fromMe: false,
          text: { message: 'Filtered message' }
        }
      end

      it 'does not process group messages' do
        params[:isGroup] = true

        expect do
          service.perform
        end.not_to change(Message, :count)
      end

      it 'does not process newsletter messages' do
        params[:isNewsletter] = true

        expect do
          service.perform
        end.not_to change(Message, :count)
      end

      it 'does not process broadcast messages' do
        params[:broadcast] = true

        expect do
          service.perform
        end.not_to change(Message, :count)
      end

      it 'does not process status reply messages' do
        params[:isStatusReply] = true

        expect do
          service.perform
        end.not_to change(Message, :count)
      end
    end

    context 'when processing attachment with file extensions' do
      let(:params) do
        {
          type: 'ReceivedCallback',
          messageId: 'ext_123',
          momment: Time.current.to_i * 1000,
          phone: '5511987654321',
          chatLid: '5511987654321',
          fromMe: false,
          document: {
            fileName: 'report.xlsx',
            documentUrl: 'https://example.com/report.xlsx',
            mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
          }
        }
      end

      before do
        stub_request(:get, 'https://example.com/report.xlsx')
          .to_return(status: 200, body: 'fake excel data',
                     headers: { 'Content-Type' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' })
      end

      it 'preserves original filename and extension' do
        service.perform

        message = Message.last
        attachment = message.attachments.first
        expect(attachment.file.filename.to_s).to eq('report.xlsx')
        expect(attachment.file.content_type).to eq('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
      end
    end

    context 'when processing contact message' do
      context 'with single phone number' do
        let(:params) do
          {
            type: 'ReceivedCallback',
            messageId: 'contact_123',
            momment: Time.current.to_i * 1000,
            phone: '1234567890',
            chatLid: '1234567890@lid',
            fromMe: false,
            contact: {
              displayName: 'Test Contact Name',
              vCard: "BEGIN:VCARD\nVERSION:3.0\nFN:Test Contact Name\nTEL;type=CELL:+1111111111\nEND:VCARD",
              phones: ['1111111111']
            }
          }
        end

        it 'creates a message with contact attachment' do
          expect do
            service.perform
          end.to change(Message, :count).by(1)

          message = Message.last
          expect(message.content).to eq('Test Contact Name')
          expect(message.attachments.count).to eq(1)
        end

        it 'creates contact attachment with correct file_type' do
          service.perform

          attachment = Message.last.attachments.first
          expect(attachment.file_type).to eq('contact')
        end

        it 'stores phone number in fallback_title' do
          service.perform

          attachment = Message.last.attachments.first
          expect(attachment.fallback_title).to eq('1111111111')
        end

        it 'extracts firstName and lastName from displayName' do
          service.perform

          attachment = Message.last.attachments.first
          expect(attachment.meta['firstName']).to eq('Test')
          expect(attachment.meta['lastName']).to eq('Contact Name')
        end
      end

      context 'with multiple phone numbers' do
        let(:params) do
          {
            type: 'ReceivedCallback',
            messageId: 'contact_456',
            momment: Time.current.to_i * 1000,
            phone: '1234567890',
            chatLid: '1234567890@lid',
            fromMe: false,
            contact: {
              displayName: 'Sample User',
              vCard: "BEGIN:VCARD\nVERSION:3.0\nFN:Sample User\nTEL;type=CELL:+2222222222\nTEL;type=WORK:+3333333333\nEND:VCARD",
              phones: %w[2222222222 3333333333]
            }
          }
        end

        it 'creates a message for each phone number' do
          expect do
            service.perform
          end.to change(Message, :count).by(2)

          messages = Message.last(2)
          expect(messages.all? { |m| m.content == 'Sample User' }).to be(true)
        end

        it 'creates an attachment for each phone number' do
          service.perform

          messages = Message.last(2)
          expect(messages[0].attachments.count).to eq(1)
          expect(messages[1].attachments.count).to eq(1)
        end

        it 'stores different phone numbers in fallback_title' do
          service.perform

          attachments = Message.last(2).map { |m| m.attachments.first }
          expect(attachments[0].fallback_title).to eq('2222222222')
          expect(attachments[1].fallback_title).to eq('3333333333')
        end

        it 'uses the same source_id for all messages' do
          service.perform

          messages = Message.last(2)
          expect(messages.map(&:source_id).uniq).to eq(['contact_456'])
        end
      end

      context 'with no phone numbers' do
        let(:params) do
          {
            type: 'ReceivedCallback',
            messageId: 'contact_789',
            momment: Time.current.to_i * 1000,
            phone: '1234567890',
            chatLid: '1234567890@lid',
            fromMe: false,
            contact: {
              displayName: 'Test User',
              vCard: "BEGIN:VCARD\nVERSION:3.0\nFN:Test User\nEND:VCARD",
              phones: []
            }
          }
        end

        it 'creates message with fallback text' do
          expect do
            service.perform
          end.to change(Message, :count).by(1)

          message = Message.last
          expect(message.content).to eq('Test User')
        end

        it 'creates attachment with "Phone number is not available" as fallback_title' do
          service.perform

          attachment = Message.last.attachments.first
          expect(attachment.fallback_title).to eq('Phone number is not available')
        end
      end

      context 'with single-word name' do
        let(:params) do
          {
            type: 'ReceivedCallback',
            messageId: 'contact_single',
            momment: Time.current.to_i * 1000,
            phone: '1234567890',
            chatLid: '1234567890@lid',
            fromMe: false,
            contact: {
              displayName: 'SingleName',
              vCard: "BEGIN:VCARD\nVERSION:3.0\nFN:SingleName\nTEL:+4444444444\nEND:VCARD",
              phones: ['4444444444']
            }
          }
        end

        it 'extracts firstName only when no last name' do
          service.perform

          attachment = Message.last.attachments.first
          expect(attachment.meta['firstName']).to eq('SingleName')
          expect(attachment.meta.key?('lastName')).to be(false)
        end
      end

      context 'when contact message comes from user (outgoing)' do
        let(:params) do
          {
            type: 'ReceivedCallback',
            messageId: 'contact_outgoing',
            momment: Time.current.to_i * 1000,
            phone: '1234567890',
            chatLid: '1234567890@lid',
            fromMe: true,
            contact: {
              displayName: 'Outgoing Contact',
              vCard: "BEGIN:VCARD\nVERSION:3.0\nFN:Outgoing Contact\nTEL:+5555555555\nEND:VCARD",
              phones: ['5555555555']
            }
          }
        end

        before do
          create(:account_user, account: inbox.account)
        end

        it 'creates outgoing message with nil sender (sent from WhatsApp)' do
          service.perform

          message = Message.last
          expect(message.message_type).to eq('outgoing')
          expect(message.sender).to be_nil
          expect(message.content_attributes['external_sender_name']).to eq('WhatsApp')
        end

        it 'creates contact attachment for outgoing message' do
          service.perform

          message = Message.last
          expect(message.attachments.count).to eq(1)
          expect(message.attachments.first.file_type).to eq('contact')
        end
      end
    end
  end

  describe '#process_received_callback with locking' do
    let(:params) do
      {
        type: 'ReceivedCallback',
        messageId: 'msg_123',
        momment: Time.current.to_i * 1000,
        fromMe: false,
        chatName: 'John Doe',
        text: { message: 'Hello' },
        phone: '5511987654321',
        chatLid: '123456789@lid'
      }
    end

    it 'acquires a lock on the contact phone number' do
      allow(Redis::Alfred).to receive(:set).and_return(true)
      allow(Redis::Alfred).to receive(:delete)

      service.perform

      expect(Redis::Alfred).to have_received(:set).with('ZAPI::CONTACT_LOCK::5511987654321', 1, nx: true, ex: 5.seconds)
      expect(Redis::Alfred).to have_received(:delete).with('ZAPI::CONTACT_LOCK::5511987654321')
    end

    it 'waits for the lock if it is already acquired' do
      # Stub the message processing lock to always succeed
      allow(Redis::Alfred).to receive(:set)
        .with(format_message_source_key('msg_123'), true, nx: true, ex: 1.day)
        .and_return(true)
      allow(Redis::Alfred).to receive(:set).with('ZAPI::CONTACT_LOCK::5511987654321', 1, nx: true, ex: 5.seconds).and_return(false, true)
      allow(Redis::Alfred).to receive(:delete)

      allow(service).to receive(:sleep).with(0.1)

      service.perform

      expect(service).to have_received(:sleep).with(0.1).once
    end
  end

  private

  def format_message_source_key(message_id)
    format(Redis::RedisKeys::MESSAGE_SOURCE_KEY, id: "#{inbox.id}_#{message_id}")
  end
end
