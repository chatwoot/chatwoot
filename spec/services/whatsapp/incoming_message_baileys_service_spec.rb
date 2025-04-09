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
        let(:raw_message) do
          {
            key: { id: 'msg_123', remoteJid: '5511912345678@s.whatsapp.net', fromMe: false },
            message: { conversation: 'Hello from Baileys' },
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

        context 'when has key conversation' do # rubocop:disable RSpec/NestedGroups
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

          it 'creates an outgoing message' do
            number = '5511912345678'
            raw_message_outgoing = raw_message.merge(
              key: { id: 'msg_123', remoteJid: "#{number}@s.whatsapp.net", fromMe: true }
            )
            params_outgoing = params.merge(data: { type: 'notify', messages: [raw_message_outgoing] })
            create(:account_user, account: inbox.account)

            described_class.new(inbox: inbox, params: params_outgoing).perform

            conversation = inbox.conversations.last
            message = conversation.messages.last
            expect(message).to be_present
            expect(message.content).to eq('Hello from Baileys')
            expect(message.message_type).to eq('outgoing')
            expect(conversation.contact.name).to eq("+#{number}")
          end

          it 'updates the contact name if the current name is a phone number when a incoming message is received' do
            create(:contact, account: inbox.account, name: '+5511912345678', phone_number: '+5511912345678')
            described_class.new(inbox: inbox, params: params).perform

            conversation = inbox.conversations.last
            expect(conversation.contact.name).to eq('John Doe')
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
