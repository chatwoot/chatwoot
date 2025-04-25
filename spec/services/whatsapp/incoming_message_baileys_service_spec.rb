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
      context 'when message type is unsupported' do
        let(:raw_message) do
          {
            key: { id: 'msg_123', remoteJid: '5511912345678@s.whatsapp.net', fromMe: false },
            message: { unsupported: 'message' },
            pushName: 'John Doe'
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

        it 'creates an alert of unsupported message' do
          described_class.new(inbox: inbox, params: params).perform

          conversation = inbox.conversations.last
          message = conversation.messages.last

          expect(message).to be_present
          expect(message.content).to eq(I18n.t('errors.messages.unsupported'))
          expect(message.message_type).to eq('template')
          expect(message.status).to eq('failed')
        end

        it 'logs a warning message' do
          allow(Rails.logger).to receive(:warn).with('Baileys unsupported message type: unsupported')

          described_class.new(inbox: inbox, params: params).perform

          expect(Rails.logger).to have_received(:warn)
        end
      end

      context 'when message is not from a user' do
        let(:raw_message) do
          {
            key: { id: 'msg_123', remoteJid: 'status@broadcast', participant: '5511912345678@s.whatsapp.net', fromMe: false },
            message: { extendedTextMessage: { text: 'message' } },
            pushName: 'John Doe'
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

        it 'does not create a conversation' do
          described_class.new(inbox: inbox, params: params).perform

          expect(inbox.conversations).to be_empty
        end
      end

      context 'when message type is text' do
        let(:phone_number) { '5511912345678' }
        let(:jid) { "#{phone_number}@s.whatsapp.net" }
        let(:content_message) { 'Hello from Baileys' }
        let(:raw_message) do
          {
            key: { id: 'msg_123', remoteJid: jid, fromMe: false },
            pushName: 'John Doe',
            message: { conversation: content_message }
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

        context 'when has key conversation' do # rubocop:disable RSpec/NestedGroups
          it 'creates an incoming message' do
            described_class.new(inbox: inbox, params: params).perform

            conversation = inbox.conversations.last
            message = conversation.messages.last

            expect(message).to be_present
            expect(message.content).to eq(content_message)
            expect(message.sender).to be_present
            expect(message.sender.name).to eq('John Doe')
            expect(message.message_type).to eq('incoming')
          end

          it 'creates an outgoing message' do
            raw_message_outgoing = raw_message.merge(key: { id: 'msg_123', remoteJid: jid, fromMe: true })
            params_outgoing = params.merge(data: { type: 'notify', messages: [raw_message_outgoing] })
            create(:account_user, account: inbox.account)

            described_class.new(inbox: inbox, params: params_outgoing).perform

            conversation = inbox.conversations.last
            message = conversation.messages.last

            expect(message).to be_present
            expect(message.content).to eq(content_message)
            expect(conversation.contact.name).to eq(phone_number)
            expect(message.message_type).to eq('outgoing')
          end

          it 'creates an outgoing self message' do
            self_jid = "#{whatsapp_channel.phone_number.delete('+')}@s.whatsapp.net"
            raw_message_outgoing = raw_message.merge(key: { id: 'msg_123', remoteJid: self_jid, fromMe: true })
            params_outgoing = params.merge(data: { type: 'notify', messages: [raw_message_outgoing] })
            create(:account_user, account: inbox.account)

            described_class.new(inbox: inbox, params: params_outgoing).perform

            conversation = inbox.conversations.last
            message = conversation.messages.last

            expect(message).to be_present
            expect(message.content).to eq(content_message)
            expect(conversation.contact.name).to eq('John Doe')
            expect(message.message_type).to eq('outgoing')
          end

          it 'updates the contact name when name is the phone number and message has a pushName' do
            create(:contact, account: inbox.account, name: phone_number)

            described_class.new(inbox: inbox, params: params).perform

            conversation = inbox.conversations.last
            expect(conversation.contact.name).to eq('John Doe')
          end

          it 'updates the contact name when name is the phone number and message has a verifiedBizName' do
            raw_message[:verifiedBizName] = 'Verified John'
            create(:contact, account: inbox.account, name: phone_number)

            described_class.new(inbox: inbox, params: params).perform

            conversation = inbox.conversations.last
            expect(conversation.contact.name).to eq('Verified John')
          end

          it 'creates contact with phone number as name on outgoing message' do
            raw_message_outgoing = raw_message.merge(key: { id: 'msg_123', remoteJid: jid, fromMe: true })
            params_outgoing = params.merge(data: { type: 'notify', messages: [raw_message_outgoing] })
            create(:account_user, account: inbox.account)

            described_class.new(inbox: inbox, params: params_outgoing).perform

            conversation = inbox.conversations.last
            expect(conversation.contact.name).to eq(phone_number)
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
          let(:raw_message) do
            {
              key: { id: 'msg_123', remoteJid: '5511912345678@s.whatsapp.net', fromMe: false },
              message: { extendedTextMessage: { text: 'Hello from Baileys' } },
              pushName: 'John Doe'
            }
          end

          it 'creates an incoming message' do
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

      context 'when message type is image' do
        let(:raw_message) do
          {
            key: { id: 'msg_123', remoteJid: '5511912345678@s.whatsapp.net', fromMe: false },
            message: { imageMessage: { caption: 'Hello from Baileys' } },
            pushName: 'John Doe'
          }
        end
        let(:params) do
          {
            webhookVerifyToken: webhook_verify_token,
            event: 'messages.upsert',
            data: {
              type: 'notify',
              messages: [raw_message]
            },
            extra: {
              media: {
                'msg_123' => 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII='
              }
            }
          }
        end

        it 'creates the message with caption' do
          described_class.new(inbox: inbox, params: params).perform
          conversation = inbox.conversations.last
          message = conversation.messages.last

          expect(message).to be_present
          expect(message.content).to eq('Hello from Baileys')
        end

        it 'creates message attachment' do
          freeze_time

          described_class.new(inbox: inbox, params: params).perform

          conversation = inbox.conversations.last
          message = conversation.messages.last
          attachment = message.attachments.last

          expect(attachment).to be_present
          expect(attachment.file).to be_present
          expect(attachment.file_type).to eq('image')

          expect(attachment.file.filename.to_s).to eq("image_#{message.id}_#{Time.current.strftime('%Y%m%d')}")
          expect(attachment.file.content_type).to eq('image/png')
        end
      end

      context 'when message type is video' do
        let(:raw_message) do
          {
            key: { id: 'msg_123', remoteJid: '5511912345678@s.whatsapp.net', fromMe: false },
            message: { videoMessage: { caption: 'Hello from Baileys' } },
            pushName: 'John Doe'
          }
        end
        let(:params) do
          {
            webhookVerifyToken: webhook_verify_token,
            event: 'messages.upsert',
            data: {
              type: 'notify',
              messages: [raw_message]
            },
            extra: {
              media: {
                'msg_123' => 'AAAAHGZ0eXBpc29tAAACAGlzb21pc28ybXA0MQAAAAhmcmVlAAABL21kYXQAAAGzABAHAAABthGBxgj238bbfxtt/G238bbfxtt/G238bbfxtt/G238bbfxtt/G238bbfxtt/G237wAAAbMAEAcAAAG2E4HGCkbckbbfxtt/G238bbfxtt/G238bbfxtt/G238bbfxtt/G238bbfxtt/G237AAABswAQBwAAAbYVgcYLltyRtt/G238bbfxtt/G238bbfxtt/G238bbfxtt/G238bbfxtt/G238bbfsAAAGzABAHAAABtheBxhPbckbbfxtt/G238bbfxtt/G238bbfxtt/G238bbfxtt/G238bbfxtt/G237wAAAbMAEAcAAAG2GYHGJG3JG238bbfxtt/G238bbfxtt/G238bbfxtt/G238bbfxtt/G238bbfxtt+/AAADHW1vb3YAAABsbXZoZAAAAAAAAAAAAAAAAAAAA+gAAAPoAAEAAAEAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAAAJHdHJhawAAAFx0a2hkAAAAAwAAAAAAAAAAAAAAAQAAAAAAAAPoAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAQAAAAABAAAAAQAAAAAAAJGVkdHMAAAAcZWxzdAAAAAAAAAABAAAD6AAAAAAAAQAAAAABv21kaWEAAAAgbWRoZAAAAAAAAAAAAAAAAAAAKAAAACgAVcQAAAAAAC1oZGxyAAAAAAAAAAB2aWRlAAAAAAAAAAAAAAAAVmlkZW9IYW5kbGVyAAAAAWptaW5mAAAAFHZtaGQAAAABAAAAAAAAAAAAAAAkZGluZgAAABxkcmVmAAAAAAAAAAEAAAAMdXJsIAAAAAEAAAEqc3RibAAAAGJzdHNkAAAAAAAAACVhdmMxAAAAAAAAAAAAAAAAAACFc3R0cwAAAAAAAAABAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' # rubocop:disable Layout/LineLength
              }
            }
          }
        end

        it 'creates the message with caption' do
          described_class.new(inbox: inbox, params: params).perform
          conversation = inbox.conversations.last
          message = conversation.messages.last

          expect(message).to be_present
          expect(message.content).to eq('Hello from Baileys')
        end

        it 'creates message attachment' do
          freeze_time

          described_class.new(inbox: inbox, params: params).perform

          conversation = inbox.conversations.last
          message = conversation.messages.last
          attachment = message.attachments.last

          expect(attachment).to be_present
          expect(attachment.file).to be_present
          expect(attachment.file_type).to eq('video')

          expect(attachment.file.filename.to_s).to eq("video_#{message.id}_#{Time.current.strftime('%Y%m%d')}")
          expect(attachment.file.content_type).to eq('video/mp4')
        end
      end

      context 'when message type is file' do
        let(:filename) { 'file.pdf' }
        let(:raw_message) do
          {
            key: { id: 'msg_123', remoteJid: '5511912345678@s.whatsapp.net', fromMe: false },
            message: { documentMessage: { fileName: filename } },
            pushName: 'John Doe'
          }
        end
        let(:params) do
          {
            webhookVerifyToken: webhook_verify_token,
            event: 'messages.upsert',
            data: {
              type: 'notify',
              messages: [raw_message]
            },
            extra: {
              media: {
                'msg_123' => 'JVBERi0xLjQKJVRlc3QgUERGCjEgMCBvYmoKPDwgL1R5cGUgL0NhdGFsb2cgL091dGxpbmVzIDIgMCBSIC9QYWdlcyAzIDAgUiA+PgplbmRvYmoKMiAwIG9iago8PCAvVHlwZSAvT3V0bGluZXMgL0NvdW50IDAgPj4KZW5kb2JqCjMgMCBvYmoKPDwgL1R5cGUgL1BhZ2VzIC9LaWRzIFs0IDAgUl0gL0NvdW50IDEgPj4KZW5kb2JqCjQgMCBvYmoKPDwgL1R5cGUgL1BhZ2UgCiAgIC9QYXJlbnQgMyAwIFIgCiAgIC9NZWRpYUJveCBbMCAwIDMwMCAyMDBdIAogICAvQ29udGVudHMgNSAwIFIgCiAgIC9SZXNvdXJjZXMgPDwgL0ZvbnQgPDwgL0YxIDw8IC9UeXBlIC9Gb250IC9TdWJ0eXBlIC9UeXBlMSAvQmFzZUZvbnQgL0hlbHZldGljYSA+PiA+PiA+PgplbmRvYmoKNSAwIG9iago8PCAvTGVuZ3RoIDUzID4+CnN0cmVhbQpCVAovRjEgMTIgVGYKNzIgMTUwIFRkCihIZWxsbyBQREYhKSBUagpFVAplbmRzdHJlYW0KZW5kb2JqCnhyZWYKMCA2CjAwMDAwMDAwMDAgNjU1MzUgZiAKMDAwMDAwMDAxNyAwMDAwMCBuIAowMDAwMDAwMDg0IDAwMDAwIG4gCjAwMDAwMDAxMzQgMDAwMDAgbiAKMDAwMDAwMDE5MyAwMDAwMCBuIAowMDAwMDAwMzkxIDAwMDAwIG4gCnRyYWlsZXIKPDwgL1NpemUgNiAvUm9vdCAxIDAgUiA+PgpzdGFydHhyZWYKNDk0CiUlRU9GCg==' # rubocop:disable Layout/LineLength
              }
            }
          }
        end

        it 'creates message attachment' do
          described_class.new(inbox: inbox, params: params).perform

          conversation = inbox.conversations.last
          message = conversation.messages.last
          attachment = message.attachments.last

          expect(attachment).to be_present
          expect(attachment.file_type).to eq('file')
          expect(attachment.file).to be_present

          expect(attachment.file.filename.to_s).to eq(filename)
          expect(attachment.file.content_type).to eq('application/pdf')
        end
      end

      context 'when message type is audio' do
        let(:raw_message) do
          {
            key: { id: 'msg_123', remoteJid: '5511912345678@s.whatsapp.net', fromMe: false },
            message: { audioMessage: {} },
            pushName: 'John Doe'
          }
        end
        let(:params) do
          {
            webhookVerifyToken: webhook_verify_token,
            event: 'messages.upsert',
            data: {
              type: 'notify',
              messages: [raw_message]
            },
            extra: {
              media: {
                'msg_123' => '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' # rubocop:disable Layout/LineLength
              }
            }
          }
        end

        it 'creates message attachment' do
          freeze_time

          described_class.new(inbox: inbox, params: params).perform

          conversation = inbox.conversations.last
          message = conversation.messages.last
          attachment = message.attachments.last

          expect(attachment).to be_present
          expect(attachment.file_type).to eq('audio')
          expect(attachment.file).to be_present

          expect(attachment.file.filename.to_s).to eq("audio_#{message.id}_#{Time.current.strftime('%Y%m%d')}")
          expect(attachment.file.content_type).to eq('audio/opus')
        end
      end

      context 'when message type is sticker' do
        let(:raw_message) do
          {
            key: { id: 'msg_123', remoteJid: '5511912345678@s.whatsapp.net', fromMe: false },
            message: { stickerMessage: {} },
            pushName: 'John Doe'
          }
        end
        let(:params) do
          {
            webhookVerifyToken: webhook_verify_token,
            event: 'messages.upsert',
            data: {
              type: 'notify',
              messages: [raw_message]
            },
            extra: {
              media: {
                'msg_123' => 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII='
              }
            }
          }
        end

        it 'creates message attachment' do
          freeze_time

          described_class.new(inbox: inbox, params: params).perform

          conversation = inbox.conversations.last
          message = conversation.messages.last
          attachment = message.attachments.last

          expect(attachment).to be_present
          expect(attachment.file_type).to eq('image')
          expect(attachment.file).to be_present

          expect(attachment.file.filename.to_s).to eq("image_#{message.id}_#{Time.current.strftime('%Y%m%d')}")
          expect(attachment.file.content_type).to eq('image/png')
        end
      end
    end

    context 'when processing messages.update event' do
      context 'when message is not found' do
        let(:message_id) { 'msg_123' }
        let(:update_payload) do
          {
            key: { id: message_id },
            update: {
              status: 2
            }
          }
        end

        it 'raises MessageNotFoundError' do
          params = {
            webhookVerifyToken: webhook_verify_token,
            event: 'messages.update',
            data: [update_payload]
          }

          expect do
            described_class.new(inbox: inbox, params: params).perform
          end.to raise_error(Whatsapp::IncomingMessageBaileysService::MessageNotFoundError)
        end
      end

      context 'when message is found' do
        let(:message_id) { 'msg_123' }
        let!(:message) { create(:message, source_id: message_id, status: 'sent') }

        it 'updates the message status' do
          update_payload = { key: { id: message_id }, update: { status: 3 } }
          params = {
            webhookVerifyToken: webhook_verify_token,
            event: 'messages.update',
            data: [update_payload]
          }

          described_class.new(inbox: inbox, params: params).perform

          expect(message.reload.status).to eq('delivered')
        end

        it 'updates the message content' do
          update_payload = {
            key: { id: message_id },
            update: {
              message: { editedMessage: { message: { conversation: 'New message content' } } }
            }
          }
          params = {
            webhookVerifyToken: webhook_verify_token,
            event: 'messages.update',
            data: [update_payload]
          }

          described_class.new(inbox: inbox, params: params).perform

          expect(message.reload.content).to eq('New message content')
        end
      end

      context 'when the status transition is not allowed (message already read)' do
        let(:message_id) { 'msg_123' }
        let!(:message) { create(:message, source_id: message_id, status: 'read') }

        it 'does not update the status' do
          update_payload = { key: { id: message_id }, update: { status: 3 } }
          params = {
            webhookVerifyToken: webhook_verify_token,
            event: 'messages.update',
            data: [update_payload]
          }

          described_class.new(inbox: inbox, params: params).perform

          expect(message.reload.status).to eq('read')
        end
      end

      context 'when update unsupported status' do
        let(:message_id) { 'msg_123' }
        let!(:message) { create(:message, source_id: message_id) } # rubocop:disable RSpec/LetSetup

        it 'logs warning for unsupported played status' do
          update_payload = { key: { id: message_id }, update: { status: 5 } }
          params = {
            webhookVerifyToken: webhook_verify_token,
            event: 'messages.update',
            data: [update_payload]
          }
          allow(Rails.logger).to receive(:warn).with('Baileys unsupported message update status: PLAYED(5)')

          described_class.new(inbox: inbox, params: params).perform

          expect(Rails.logger).to have_received(:warn)
        end

        it 'logs warning for unsupported status' do
          update_payload = { key: { id: message_id }, update: { status: 6 } }
          params = {
            webhookVerifyToken: webhook_verify_token,
            event: 'messages.update',
            data: [update_payload]
          }
          allow(Rails.logger).to receive(:warn).with('Baileys unsupported message update status: 6')

          described_class.new(inbox: inbox, params: params).perform

          expect(Rails.logger).to have_received(:warn)
        end
      end
    end
  end

  def format_message_source_key(message_id)
    format(Redis::RedisKeys::MESSAGE_SOURCE_KEY, id: message_id)
  end
end
