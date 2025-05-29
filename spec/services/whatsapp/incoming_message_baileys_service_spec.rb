require 'rails_helper'

describe Whatsapp::IncomingMessageBaileysService do
  describe '#perform' do
    let(:webhook_verify_token) { 'valid_token' }
    let!(:whatsapp_channel) do
      create(:channel_whatsapp,
             provider: 'baileys',
             provider_config: { webhook_verify_token: webhook_verify_token },
             validate_provider_config: false)
    end
    let(:inbox) { whatsapp_channel.inbox }

    context 'when webhook verify token is invalid' do
      it 'raises an InvalidWebhookVerifyToken error' do
        params = { webhookVerifyToken: 'invalid_token' }

        expect do
          described_class.new(inbox: inbox, params: params).perform
        end.to raise_error(Whatsapp::IncomingMessageBaileysService::InvalidWebhookVerifyToken)
      end
    end

    context 'when event is blank' do
      it 'returns early and does nothing' do
        params = {
          webhookVerifyToken: webhook_verify_token,
          event: '',
          data: { connection: 'open' }
        }
        service = described_class.new(inbox: inbox, params: params)
        allow(service).to receive(:respond_to?)

        service.perform

        expect(service).not_to have_received(:respond_to?)
      end
    end

    context 'when data is blank' do
      it 'returns early and does nothing' do
        params = {
          webhookVerifyToken: webhook_verify_token,
          event: 'connection.update',
          data: {}
        }
        service = described_class.new(inbox: inbox, params: params)
        allow(service).to receive(:respond_to?)

        service.perform

        expect(service).not_to have_received(:respond_to?)
      end
    end

    context 'when event is unsupported' do
      it 'logs a warning message' do
        params = {
          webhookVerifyToken: webhook_verify_token,
          event: 'unsupported.event',
          data: 'some-data'
        }
        allow(Rails.logger).to receive(:warn).with('Baileys unsupported event: unsupported.event')

        described_class.new(inbox: inbox, params: params).perform

        expect(Rails.logger).to have_received(:warn)
      end
    end

    context 'when processing connection.update event' do
      let(:base_params) { { webhookVerifyToken: webhook_verify_token, event: 'connection.update' } }

      it 'updates the channel provider_connection' do
        params = base_params.merge(
          {
            data: {
              connection: 'open',
              qrDataUrl: 'data:image/jpeg;base64,',
              error: 'wrong_phone_number'
            }
          }
        )

        described_class.new(inbox: inbox, params: params).perform

        expect(inbox.channel.provider_connection).to include(
          'connection' => 'open',
          'qr_data_url' => 'data:image/jpeg;base64,',
          'error' => I18n.t('errors.inboxes.channel.provider_connection.wrong_phone_number')
        )
      end

      it "logs an error message if there's an error" do
        params = base_params.merge(
          {
            data: { error: 'wrong_phone_number' }
          }
        )
        allow(Rails.logger).to receive(:error).with('Baileys connection error: wrong_phone_number')

        described_class.new(inbox: inbox, params: params).perform

        expect(Rails.logger).to have_received(:error)
      end

      it "keeps connection value if it's not present in the data" do
        inbox.channel.update_provider_connection!(connection: 'connecting')
        params = base_params.merge(
          {
            data: { qrDataUrl: 'data:image/jpeg;base64,' }
          }
        )

        described_class.new(inbox: inbox, params: params).perform

        expect(inbox.channel.provider_connection['connection']).to eq('connecting')
      end

      it "removes qr_data_url value if it's not present in the data" do
        inbox.channel.update_provider_connection!(qr_data_url: 'data:image/jpeg;base64,')
        params = base_params.merge(
          {
            data: { connection: 'open' }
          }
        )

        described_class.new(inbox: inbox, params: params).perform

        expect(inbox.channel.provider_connection['qr_data_url']).to be_nil
      end

      it "removes error value if it's not present in the data" do
        inbox.channel.update_provider_connection!(error: 'wrong_phone_number')
        params = base_params.merge(
          {
            data: { connection: 'open' }
          }
        )

        described_class.new(inbox: inbox, params: params).perform

        expect(inbox.channel.provider_connection['error']).to be_nil
      end
    end

    context 'when processing messages.upsert event' do
      let(:timestamp) { Time.current.to_i }
      let(:raw_message) do
        {
          key: { id: 'msg_123', remoteJid: '5511912345678@s.whatsapp.net', fromMe: false },
          pushName: 'John Doe',
          messageTimestamp: timestamp,
          message: { conversation: 'Hello from Baileys' }
        }
      end
      let(:params) do
        {
          webhookVerifyToken: webhook_verify_token,
          event: 'messages.upsert',
          data: {
            type: 'notify',
            messages: [raw_message]
          }
        }
      end

      it 'creates message with external_created_at' do
        described_class.new(inbox: inbox, params: params).perform

        conversation = inbox.conversations.last
        message = conversation.messages.last

        expect(message).to be_present
        expect(message.content_attributes[:external_created_at]).to eq(timestamp)
      end

      context 'when message type is unsupported' do
        it 'creates message with is_unsupported' do
          raw_message[:message] = { unsupported: 'message' }

          described_class.new(inbox: inbox, params: params).perform

          conversation = inbox.conversations.last
          message = conversation.messages.last

          expect(message).to be_present
          expect(message.content_attributes[:is_unsupported]).to be(true)
        end
      end

      context 'when message is protocol message' do
        it 'does not create contact inbox nor message' do
          raw_message[:message] = { protocolMessage: { type: 1 } }

          described_class.new(inbox: inbox, params: params).perform

          expect(inbox.messages).to be_empty
          expect(inbox.contact_inboxes).to be_empty
        end
      end

      context 'when message is not from a user' do
        it 'does not create a conversation' do
          raw_message[:key][:remoteJid] = 'status@broadcast'

          described_class.new(inbox: inbox, params: params).perform

          expect(inbox.conversations).to be_empty
        end
      end

      context 'when message type is text' do
        context 'when has key conversation' do # rubocop:disable RSpec/NestedGroups
          it 'creates an incoming message' do
            described_class.new(inbox: inbox, params: params).perform

            conversation = inbox.conversations.last
            message = conversation.messages.last

            expect(message).to be_present
            expect(message.content).to eq('Hello from Baileys')
            expect(message.sender).to be_present
            expect(message.sender.name).to eq('John Doe')
            expect(message.message_type).to eq('incoming')
          end

          it 'creates an outgoing message' do
            raw_message[:key][:fromMe] = true
            create(:account_user, account: inbox.account)

            described_class.new(inbox: inbox, params: params).perform

            conversation = inbox.conversations.last
            message = conversation.messages.last

            expect(message).to be_present
            expect(message.content).to eq('Hello from Baileys')
            expect(conversation.contact.name).to eq('5511912345678')
            expect(message.message_type).to eq('outgoing')
          end

          it 'creates an outgoing self message' do
            self_jid = "#{whatsapp_channel.phone_number.delete('+')}@s.whatsapp.net"
            raw_message[:key][:remoteJid] = self_jid
            raw_message[:key][:fromMe] = true
            create(:account_user, account: inbox.account)

            described_class.new(inbox: inbox, params: params).perform

            conversation = inbox.conversations.last
            message = conversation.messages.last

            expect(message).to be_present
            expect(message.content).to eq('Hello from Baileys')
            expect(conversation.contact.name).to eq('John Doe')
            expect(message.message_type).to eq('outgoing')
          end

          it 'updates the contact name when name is the phone number and message has a pushName' do
            create(:contact, account: inbox.account, name: '5511912345678')

            described_class.new(inbox: inbox, params: params).perform

            conversation = inbox.conversations.last
            expect(conversation.contact.name).to eq('John Doe')
          end

          it 'updates the contact name when name is the phone number and message has a verifiedBizName' do
            raw_message[:verifiedBizName] = 'Verified John'
            create(:contact, account: inbox.account, name: '5511912345678')

            described_class.new(inbox: inbox, params: params).perform

            conversation = inbox.conversations.last
            expect(conversation.contact.name).to eq('Verified John')
          end

          it 'creates contact with phone number as name on outgoing message' do
            raw_message[:key][:fromMe] = true
            create(:account_user, account: inbox.account)

            described_class.new(inbox: inbox, params: params).perform

            conversation = inbox.conversations.last
            expect(conversation.contact.name).to eq('5511912345678')
          end

          it 'creates a message on an existing conversation' do
            contact = create(:contact, account: inbox.account, name: 'John Doe')
            contact_inbox = create(:contact_inbox, inbox: inbox, contact: contact, source_id: '5511912345678')
            existing_conversation = create(:conversation, inbox: inbox, contact_inbox: contact_inbox)

            described_class.new(inbox: inbox, params: params).perform

            message = existing_conversation.messages.last
            expect(message.sender).to eq(contact)
          end

          it 'does not create a message if it already exists' do
            message = create(:message, inbox: inbox, source_id: 'msg_123')

            described_class.new(inbox: inbox, params: params).perform

            conversation = inbox.conversations.last
            messages = conversation.messages
            expect(messages).to eq([message])
          end

          it 'does not create a message if it is already being processed' do
            allow(Redis::Alfred).to receive(:get).with(format_message_source_key('msg_123')).and_return(true)

            described_class.new(inbox: inbox, params: params).perform

            expect(inbox.conversations).to be_empty
          end

          it 'caches the message source id in Redis and clears it' do
            allow(Redis::Alfred).to receive(:setex).with(format_message_source_key('msg_123'), true)
            allow(Redis::Alfred).to receive(:delete).with(format_message_source_key('msg_123'))

            described_class.new(inbox: inbox, params: params).perform

            expect(Redis::Alfred).to have_received(:setex)
            expect(Redis::Alfred).to have_received(:delete)
          end
        end

        context 'when is a extendedTextMessage that has key text' do # rubocop:disable RSpec/NestedGroups
          it 'creates an incoming message' do
            raw_message[:message] = { extendedTextMessage: { text: 'Hello from Baileys' } }

            described_class.new(inbox: inbox, params: params).perform

            conversation = inbox.conversations.last
            message = conversation.messages.last
            expect(message).to be_present
            expect(message.content).to eq('Hello from Baileys')
            expect(message.message_type).to eq('incoming')
            expect(message.sender).to be_present
            expect(message.sender.name).to eq('John Doe')
          end
        end
      end

      context 'when message type is reaction' do
        let!(:message) do
          contact = create(:contact, account: inbox.account, name: '5511912345678')
          contact_inbox = create(:contact_inbox, inbox: inbox, contact: contact, source_id: '5511912345678')
          conversation = create(:conversation, inbox: inbox, contact_inbox: contact_inbox)
          create(:message, inbox: inbox, conversation: conversation, source_id: 'msg_123')
        end

        it 'creates the reaction' do
          raw_message[:key][:id] = 'reaction_123'
          raw_message[:message] = {
            reactionMessage: {
              key: { remoteJid: '5511912345678@s.whatsapp.net', fromMe: true, id: 'msg_123' },
              text: '👍'
            }
          }

          described_class.new(inbox: inbox, params: params).perform

          reaction = message.conversation.messages.last
          expect(reaction.is_reaction).to be(true)
          expect(reaction.in_reply_to).to eq(message.id)
          expect(reaction.in_reply_to_external_id).to eq(message.source_id)
        end

        it 'does not create the reaction if content is empty' do
          raw_message[:key][:id] = 'reaction_123'
          raw_message[:message] = {
            reactionMessage: {
              key: { remoteJid: '5511912345678@s.whatsapp.net', fromMe: true, id: 'msg_123' },
              text: ''
            }
          }

          described_class.new(inbox: inbox, params: params).perform

          expect(message.conversation.messages.count).to eq(1)
        end
      end

      context 'when message type is image' do
        let(:params) do
          {
            webhookVerifyToken: webhook_verify_token,
            event: 'messages.upsert',
            data: {
              type: 'notify',
              messages: [
                {
                  key: { id: 'msg_123', remoteJid: '5511912345678@s.whatsapp.net', fromMe: false },
                  message: { imageMessage: { caption: 'Hello from Baileys', mimetype: 'image/png' } },
                  pushName: 'John Doe'
                }
              ]
            }
          }
        end

        it 'creates the message with caption' do
          stub_download

          described_class.new(inbox: inbox, params: params).perform

          message = inbox.conversations.last.messages.last

          expect(message.content).to eq('Hello from Baileys')
        end

        it 'creates message attachment' do
          stub_download

          described_class.new(inbox: inbox, params: params).perform

          message = inbox.conversations.last.messages.last
          attachment = message.attachments.last

          expect(attachment.file_type).to eq('image')
          expect(attachment.file.filename.to_s).to eq("image_msg_123_#{Time.current.strftime('%Y%m%d')}.png")
          expect(attachment.file.content_type).to eq('image/png')
        end

        it 'sets message as unsupported and logs error if attachment download fails' do
          allow(Down).to receive(:download).and_raise(Down::ResponseError.new('Attachment not found'))
          allow(Rails.logger).to receive(:error).with('Failed to download attachment for message msg_123: Attachment not found')

          described_class.new(inbox: inbox, params: params).perform

          expect(Rails.logger).to have_received(:error)
          message = inbox.conversations.last.messages.last
          expect(message).to be_present
          expect(message.is_unsupported).to be(true)
        end
      end

      context 'when message type is video' do
        let(:params) do
          {
            webhookVerifyToken: webhook_verify_token,
            event: 'messages.upsert',
            data: {
              type: 'notify',
              messages: [
                {
                  key: { id: 'msg_123', remoteJid: '5511912345678@s.whatsapp.net', fromMe: false },
                  message: { videoMessage: { caption: 'Hello from Baileys', mimetype: 'video/mp4' } },
                  pushName: 'John Doe'
                }
              ]
            }
          }
        end

        it 'creates the message with caption' do
          stub_download

          described_class.new(inbox: inbox, params: params).perform

          message = inbox.conversations.last.messages.last

          expect(message).to be_present
          expect(message.content).to eq('Hello from Baileys')
        end

        it 'creates message attachment' do
          stub_download

          described_class.new(inbox: inbox, params: params).perform

          message = inbox.conversations.last.messages.last
          attachment = message.attachments.last

          expect(attachment.file_type).to eq('video')
          expect(attachment.file.filename.to_s).to eq("video_msg_123_#{Time.current.strftime('%Y%m%d')}.mp4")
          expect(attachment.file.content_type).to eq('video/mp4')
        end
      end

      context 'when message type is file' do
        let(:filename) { 'file.pdf' }
        let(:params) do
          {
            webhookVerifyToken: webhook_verify_token,
            event: 'messages.upsert',
            data: {
              type: 'notify',
              messages: [
                {
                  key: { id: 'msg_123', remoteJid: '5511912345678@s.whatsapp.net', fromMe: false },
                  message: { documentMessage: { fileName: filename } },
                  pushName: 'John Doe'
                }
              ]
            }
          }
        end

        it 'creates message attachment' do
          stub_download

          described_class.new(inbox: inbox, params: params).perform

          message = inbox.conversations.last.messages.last
          attachment = message.attachments.last

          expect(attachment.file_type).to eq('file')
          expect(attachment.file.filename.to_s).to eq(filename)
          expect(attachment.file.content_type).to eq('application/pdf')
        end
      end

      context 'when message type is audio' do
        let(:params) do
          {
            webhookVerifyToken: webhook_verify_token,
            event: 'messages.upsert',
            data: {
              type: 'notify',
              messages: [
                {
                  key: { id: 'msg_123', remoteJid: '5511912345678@s.whatsapp.net', fromMe: false },
                  message: { audioMessage: { mimetype: 'audio/opus' } },
                  pushName: 'John Doe'
                }
              ]
            }
          }
        end

        it 'creates message attachment' do
          stub_download

          described_class.new(inbox: inbox, params: params).perform

          message = inbox.conversations.last.messages.last
          attachment = message.attachments.last

          expect(attachment.file_type).to eq('audio')
          expect(attachment.file.filename.to_s).to eq("audio_msg_123_#{Time.current.strftime('%Y%m%d')}.opus")
          expect(attachment.file.content_type).to eq('audio/opus')
        end
      end

      context 'when message type is sticker' do
        let(:params) do
          {
            webhookVerifyToken: webhook_verify_token,
            event: 'messages.upsert',
            data: {
              type: 'notify',
              messages: [
                {
                  key: { id: 'msg_123', remoteJid: '5511912345678@s.whatsapp.net', fromMe: false },
                  message: { stickerMessage: { mimetype: 'image/png' } },
                  pushName: 'John Doe'
                }
              ]
            }
          }
        end

        it 'creates message attachment' do
          stub_download

          described_class.new(inbox: inbox, params: params).perform

          message = inbox.conversations.last.messages.last
          attachment = message.attachments.last

          expect(attachment.file_type).to eq('image')
          expect(attachment.file.filename.to_s).to eq("image_msg_123_#{Time.current.strftime('%Y%m%d')}.png")
          expect(attachment.file.content_type).to eq('image/png')
        end
      end
    end

    context 'when processing messages.update event' do
      let(:conversation) do
        contact = create(:contact, account: inbox.account)
        contact_inbox = create(:contact_inbox, inbox: inbox, contact: contact)
        create(:conversation, inbox: inbox, contact_inbox: contact_inbox, assignee_id: contact.id)
      end
      let!(:message) { create(:message, inbox: inbox, conversation: conversation, source_id: 'msg_123', status: 'sent') }
      let(:update_payload) { { key: { id: 'msg_123' }, update: { status: 3 } } }
      let(:params) do
        {
          webhookVerifyToken: webhook_verify_token,
          event: 'messages.update',
          data: [update_payload]
        }
      end

      context 'when message is not found' do
        it 'raises MessageNotFoundError' do
          update_payload[:key][:id] = 'no_message_id'

          expect do
            described_class.new(inbox: inbox, params: params).perform
          end.to raise_error(Whatsapp::IncomingMessageBaileysService::MessageNotFoundError)
        end
      end

      context 'when is a status update' do
        it 'updates the message status' do
          described_class.new(inbox: inbox, params: params).perform

          expect(message.reload.status).to eq('delivered')
        end

        it 'updates conversation agent_last_seen_at and assignee_last_seen_at' do
          freeze_time
          update_payload[:key][:fromMe] = false
          update_payload[:update][:status] = 4

          conversation.update!(agent_last_seen_at: 1.day.ago, assignee_last_seen_at: 1.day.ago)

          described_class.new(inbox: inbox, params: params).perform

          expect(conversation.reload.agent_last_seen_at).to eq(Time.current)
          expect(conversation.assignee_last_seen_at).to eq(Time.current)
        end

        it "does not downgrade a 'read' message to delivered" do
          message.update!(status: 'read')

          described_class.new(inbox: inbox, params: params).perform

          expect(message.reload.status).to eq('read')
        end

        it 'logs warning for unsupported played status' do
          update_payload[:update][:status] = 5

          allow(Rails.logger).to receive(:warn).with('Baileys unsupported message update status: PLAYED(5)')

          described_class.new(inbox: inbox, params: params).perform

          expect(Rails.logger).to have_received(:warn)
        end

        it 'logs warning for unsupported status' do
          update_payload[:update][:status] = 6

          allow(Rails.logger).to receive(:warn).with('Baileys unsupported message update status: 6')

          described_class.new(inbox: inbox, params: params).perform

          expect(Rails.logger).to have_received(:warn)
        end
      end

      context 'when is a content update' do
        it 'updates the message content' do
          original_content = message.content
          update_payload[:update] = { message: { editedMessage: { message: { conversation: 'New message content' } } } }

          described_class.new(inbox: inbox, params: params).perform

          expect(message.reload.content).to eq('New message content')
          expect(message.is_edited).to be(true)
          expect(message.previous_content).to eq(original_content)
        end
      end

      context 'when is a content update' do
        it 'updates the message content' do
          original_content = message.content
          update_payload[:update] = { message: { editedMessage: { message: { conversation: 'New message content' } } } }

          described_class.new(inbox: inbox, params: params).perform

          expect(message.reload.content).to eq('New message content')
          expect(message.is_edited).to be(true)
          expect(message.previous_content).to eq(original_content)
        end
      end
    end
  end

  def format_message_source_key(message_id)
    format(Redis::RedisKeys::MESSAGE_SOURCE_KEY, id: message_id)
  end

  def stub_download
    allow(Down).to receive(:download)
      .with('https://baileys.api/media/msg_123', headers: inbox.channel.api_headers)
      .and_return(StringIO.new('Media data'))
  end
end
