require 'rails_helper'

describe Whatsapp::Providers::WhatsappBaileysService do
  subject(:service) { described_class.new(whatsapp_channel: whatsapp_channel) }

  let(:whatsapp_channel) { create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false) }
  let(:message) { create(:message, source_id: 'msg_123', content_attributes: { external_created_at: 123 }) }

  let(:test_send_phone_number) { '551187654321' }
  let(:test_send_jid) { '551187654321@s.whatsapp.net' }

  before do
    stub_const('Whatsapp::Providers::WhatsappBaileysService::DEFAULT_CLIENT_NAME', 'chatwoot-test')
  end

  describe '#setup_channel_provider' do
    context 'when response is successful' do
      it 'calls the connection endpoint' do
        stub_request(:post, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}")
          .with(
            headers: stub_headers(whatsapp_channel),
            body: {
              clientName: 'chatwoot-test',
              webhookUrl: whatsapp_channel.inbox.callback_webhook_url,
              webhookVerifyToken: whatsapp_channel.provider_config['webhook_verify_token'],
              includeMedia: false
            }.to_json
          )
          .to_return(status: 200)

        response = service.setup_channel_provider

        expect(response).to be(true)
      end
    end

    context 'when response is unsuccessful' do
      it 'logs the error and returns false' do
        stub_request(:post, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}")
          .with(
            headers: stub_headers(whatsapp_channel),
            body: {
              clientName: 'chatwoot-test',
              webhookUrl: whatsapp_channel.inbox.callback_webhook_url,
              webhookVerifyToken: whatsapp_channel.provider_config['webhook_verify_token'],
              includeMedia: false
            }.to_json
          )
          .to_return(
            status: 400,
            body: 'error message',
            headers: {}
          )
        allow(Rails.logger).to receive(:error).with('error message')

        response = service.setup_channel_provider

        expect(response).to be(false)
        expect(Rails.logger).to have_received(:error)
      end
    end
  end

  describe '#disconnect_channel_provider' do
    context 'when response is successful' do
      it 'disconnects the whatsapp connection' do
        stub_request(:delete, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}")
          .with(headers: stub_headers(whatsapp_channel))
          .to_return(status: 200)

        response = service.disconnect_channel_provider

        expect(response).to be(true)
      end
    end

    context 'when response is unsuccessful' do
      it 'logs the error and returns false' do
        stub_request(:delete, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}")
          .with(headers: stub_headers(whatsapp_channel))
          .to_return(
            status: 400,
            body: 'error message',
            headers: {}
          )
        allow(Rails.logger).to receive(:error).with('error message')

        response = service.disconnect_channel_provider

        expect(response).to be(false)
        expect(Rails.logger).to have_received(:error)
      end
    end
  end

  describe '#send_message' do
    let(:request_path) { "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}/send-message" }
    let(:result_body) { { 'data' => { 'key' => { 'id' => 'msg_123' } } } }

    context 'when message is unsupported' do
      it 'updates the message with content attribute is_unsupported' do
        unsupported_message = create(:message, content: nil)

        service.send_message(test_send_phone_number, unsupported_message)

        expect(unsupported_message.is_unsupported).to be(true)
      end
    end

    context 'when message has attachment' do
      let(:base64_image) { 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=' }

      before do
        message.attachments.create!(
          account_id: message.account_id,
          file_type: 'image',
          file: {
            io: StringIO.new(Base64.decode64(base64_image)),
            filename: 'image.png'
          }
        )
      end

      it 'sends the attachment message' do
        stub_request(:post, request_path)
          .with(
            headers: stub_headers(whatsapp_channel),
            body: {
              jid: test_send_jid,
              messageContent: { fileName: 'image.png', caption: message.content, image: base64_image }
            }.to_json
          )
          .to_return(
            status: 200,
            headers: { 'Content-Type' => 'application/json' },
            body: result_body.to_json
          )

        result = service.send_message(test_send_phone_number, message)

        expect(result).to eq('msg_123')
      end

      it 'omits caption if message content is empty' do
        message.update!(content: nil)
        stub_request(:post, request_path)
          .with(
            headers: stub_headers(whatsapp_channel),
            body: {
              jid: test_send_jid,
              messageContent: { fileName: 'image.png', image: base64_image }
            }.to_json
          )
          .to_return(
            status: 200,
            headers: { 'Content-Type' => 'application/json' },
            body: result_body.to_json
          )

        result = service.send_message(test_send_phone_number, message)

        expect(result).to eq('msg_123')
      end
    end

    context 'when message is an audio file' do
      let(:base64_audio) { 'UklGRiQAAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQAAAAA=' }

      before do
        message.attachments.create!(
          account_id: message.account_id,
          file_type: 'audio',
          file: {
            io: StringIO.new(Base64.decode64(base64_audio)),
            filename: 'audio.wav'
          }
        )
      end

      it 'sends the audio message' do
        stub_request(:post, request_path)
          .with(
            headers: stub_headers(whatsapp_channel),
            body: {
              jid: test_send_jid,
              messageContent: { fileName: 'audio.wav', caption: message.content, audio: base64_audio }
            }.to_json
          )
          .to_return(
            status: 200,
            headers: { 'Content-Type' => 'application/json' },
            body: result_body.to_json
          )

        result = service.send_message(test_send_phone_number, message)

        expect(result).to eq('msg_123')
      end

      it 'sends message with ptt true if message is recorded audio' do
        message.attachments.first.update!(meta: { is_recorded_audio: true })

        stub_request(:post, request_path)
          .with(
            headers: stub_headers(whatsapp_channel),
            body: {
              jid: test_send_jid,
              messageContent: { fileName: 'audio.wav', caption: message.content, audio: base64_audio, ptt: true }
            }.to_json
          )
          .to_return(
            status: 200,
            headers: { 'Content-Type' => 'application/json' },
            body: result_body.to_json
          )

        result = service.send_message(test_send_phone_number, message)

        expect(result).to eq('msg_123')
      end
    end

    context 'when message is a text' do
      it 'sends the message' do
        stub_request(:post, request_path)
          .with(
            headers: stub_headers(whatsapp_channel),
            body: {
              jid: test_send_jid,
              messageContent: { text: message.content }
            }.to_json
          )
          .to_return(
            status: 200,
            headers: { 'Content-Type' => 'application/json' },
            body: result_body.to_json
          )

        result = service.send_message(test_send_phone_number, message)

        expect(result).to eq('msg_123')
      end

      it 'updates the message external_created_at' do
        stub_request(:post, request_path)
          .with(
            headers: stub_headers(whatsapp_channel),
            body: {
              jid: test_send_jid,
              messageContent: { text: message.content }
            }.to_json
          )
          .to_return(
            status: 200,
            headers: { 'Content-Type' => 'application/json' },
            body: { 'data' => { 'key' => { 'id' => 'msg_123' }, 'messageTimestamp' => 1_748_003_165 } }.to_json
          )

        service.send_message(test_send_phone_number, message)

        expect(message.reload.content_attributes['external_created_at']).to eq(1_748_003_165)
      end
    end

    context 'when message is a reaction' do
      let(:inbox) { whatsapp_channel.inbox }
      let(:account_user) { create(:account_user, account: inbox.account) }
      let(:contact) { create(:contact, account: inbox.account, name: 'John Doe', phone_number: "+#{test_send_phone_number}") }
      let(:conversation) do
        contact_inbox = create(:contact_inbox, inbox: inbox, contact: contact, source_id: test_send_phone_number)
        create(:conversation, inbox: inbox, contact_inbox: contact_inbox)
      end

      it 'sends the reaction message for outgoing message' do
        message = create(:message, inbox: inbox, conversation: conversation, sender: account_user, message_type: 'outgoing', source_id: 'msg_123')
        reaction = create(:message, inbox: inbox, conversation: conversation, sender: account_user, content: '👍',
                                    content_attributes: { is_reaction: true, in_reply_to: message.id })
        stub_request(:post, request_path)
          .with(
            headers: stub_headers(whatsapp_channel),
            body: {
              jid: test_send_jid,
              messageContent: { react: { key: { id: message.source_id,
                                                remoteJid: test_send_jid,
                                                fromMe: true },
                                         text: '👍' } }
            }.to_json
          )
          .to_return(
            status: 200,
            headers: { 'Content-Type' => 'application/json' },
            body: { 'data' => { 'key' => { 'id' => 'reaction_123' } } }.to_json
          )

        result = service.send_message(test_send_phone_number, reaction)

        expect(result).to eq('reaction_123')
      end

      it 'sends the reaction message for incoming message' do
        message = create(:message, inbox: inbox, conversation: conversation, sender: contact, source_id: 'msg_123')
        reaction = create(:message, inbox: inbox, conversation: conversation, sender: account_user, content: '👍',
                                    content_attributes: { is_reaction: true, in_reply_to: message.id })
        stub_request(:post, request_path)
          .with(
            headers: stub_headers(whatsapp_channel),
            body: {
              jid: test_send_jid,
              messageContent: { react: { key: { id: message.source_id,
                                                remoteJid: test_send_jid,
                                                fromMe: false },
                                         text: '👍' } }
            }.to_json
          )
          .to_return(
            status: 200,
            headers: { 'Content-Type' => 'application/json' },
            body: { 'data' => { 'key' => { 'id' => 'reaction_123' } } }.to_json
          )

        result = service.send_message(test_send_phone_number, reaction)

        expect(result).to eq('reaction_123')
      end
    end

    context 'when request is unsuccessful' do
      it 'raises MessageNotSentError' do
        stub_request(:post, request_path)
          .to_return(
            status: 400,
            headers: { 'Content-Type' => 'application/json' },
            body: result_body.to_json
          )

        expect do
          service.send_message(test_send_phone_number, message)
        end.to raise_error(Whatsapp::Providers::WhatsappBaileysService::MessageNotSentError)
      end
    end
  end

  describe '#media_url' do
    it 'returns the media url' do
      media_id = '12345'
      expected_url = "#{whatsapp_channel.provider_config['provider_url']}/media/#{media_id}"

      expect(service.media_url(media_id)).to eq(expected_url)
    end
  end

  describe '#api_headers' do
    it 'returns the headers' do
      expect(service.api_headers).to eq('x-api-key' => 'test_key', 'Content-Type' => 'application/json')
    end
  end

  describe '#validate_provider_config?' do
    context 'when response is successful' do
      it 'returns true' do
        stub_request(:get, "#{whatsapp_channel.provider_config['provider_url']}/status/auth")
          .with(headers: stub_headers(whatsapp_channel))
          .to_return(status: 200, body: '', headers: {})

        expect(service.validate_provider_config?).to be(true)
      end
    end

    context 'when response is unsuccessful' do
      it 'logs the error and returns false' do
        stub_request(:get, "#{whatsapp_channel.provider_config['provider_url']}/status/auth")
          .with(headers: stub_headers(whatsapp_channel))
          .to_return(status: 400, body: 'error message', headers: {})
        allow(Rails.logger).to receive(:error).with('error message')

        expect(service.validate_provider_config?).to be(false)
        expect(Rails.logger).to have_received(:error)
      end

      context 'when provider responds with 5XX' do
        it 'updated provider connection to close' do
          whatsapp_channel.update!(provider_connection: { 'connection' => 'open' })
          allow(HTTParty).to receive(:post).with(
            "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}/send-message",
            headers: stub_headers(whatsapp_channel),
            body: {
              jid: test_send_jid,
              messageContent: { text: message.content }
            }.to_json
          ).and_raise(HTTParty::ResponseError.new(OpenStruct.new(status_code: 500)))

          expect do
            service.send_message(test_send_phone_number, message)
          end.to raise_error(HTTParty::ResponseError)

          expect(whatsapp_channel.provider_connection['connection']).to eq('close')
        end
      end
    end
  end

  describe '#read_messages' do
    it 'send read messages request' do
      stub_request(:post, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}/read-messages")
        .with(
          headers: stub_headers(whatsapp_channel),
          body: { keys: [{ id: message.source_id, remoteJid: test_send_jid, fromMe: false }] }.to_json
        ).to_return(status: 200, body: '', headers: {})

      result = service.read_messages(test_send_phone_number, [message])

      expect(result).to be(true)
    end
  end

  describe '#unread_message' do
    it 'send unread message request' do
      stub_request(:post, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}/chat-modify")
        .with(
          headers: stub_headers(whatsapp_channel),
          body: {
            jid: test_send_jid,
            mod: {
              markRead: false,
              lastMessages: [
                {
                  key: { id: 'msg_123', remoteJid: test_send_jid, fromMe: false },
                  messageTimestamp: 123
                }
              ]
            }
          }.to_json
        ).to_return(status: 200)

      result = service.unread_message(test_send_phone_number, message)

      expect(result).to be(true)
    end
  end

  describe '#toggle_typing_status' do
    let(:request_path) { "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}/presence" }

    it 'calls presence endpoint for typing on' do
      request = stub_request(:patch, request_path)
                .with(
                  headers: stub_headers(whatsapp_channel),
                  body: {
                    toJid: test_send_jid,
                    type: 'composing'
                  }.to_json
                )
                .to_return(status: 200)

      service.toggle_typing_status(test_send_phone_number, Events::Types::CONVERSATION_TYPING_ON)

      expect(request).to have_been_requested
    end

    it 'calls presence endpoint for recording' do
      request = stub_request(:patch, request_path)
                .with(
                  headers: stub_headers(whatsapp_channel),
                  body: {
                    toJid: test_send_jid,
                    type: 'recording'
                  }.to_json
                )
                .to_return(status: 200)

      service.toggle_typing_status(test_send_phone_number, Events::Types::CONVERSATION_RECORDING)

      expect(request).to have_been_requested
    end

    it 'calls presence endpoint for typing off' do
      request = stub_request(:patch, request_path)
                .with(
                  headers: stub_headers(whatsapp_channel),
                  body: {
                    toJid: test_send_jid,
                    type: 'paused'
                  }.to_json
                )
                .to_return(status: 200)

      service.toggle_typing_status(test_send_phone_number, Events::Types::CONVERSATION_TYPING_OFF)

      expect(request).to have_been_requested
    end

    it 'logs the error and returns false' do
      stub_request(:patch, request_path)
        .with(
          headers: stub_headers(whatsapp_channel),
          body: {
            toJid: test_send_jid,
            type: 'composing'
          }.to_json
        )
        .to_return(
          status: 400,
          body: 'error message',
          headers: {}
        )
      allow(Rails.logger).to receive(:error).with('error message')

      response = service.toggle_typing_status(test_send_phone_number, Events::Types::CONVERSATION_TYPING_ON)

      expect(response).to be(false)
      expect(Rails.logger).to have_received(:error)
    end
  end

  describe '#update_presence' do
    let(:request_path) { "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}/presence" }

    it 'calls presence endpoint' do
      request = stub_request(:patch, request_path)
                .with(
                  headers: stub_headers(whatsapp_channel),
                  body: {
                    type: 'available'
                  }.to_json
                )
                .to_return(status: 200)

      service.update_presence('online')

      expect(request).to have_been_requested
    end

    it 'logs the error and returns false' do
      stub_request(:patch, request_path)
        .with(
          headers: stub_headers(whatsapp_channel),
          body: {
            type: 'available'
          }.to_json
        )
        .to_return(
          status: 400,
          body: 'error message',
          headers: {}
        )
      allow(Rails.logger).to receive(:error).with('error message')

      response = service.update_presence('online')

      expect(response).to be(false)
      expect(Rails.logger).to have_received(:error)
    end
  end

  context 'when environment variable BAILEYS_PROVIDER_DEFAULT_URL is set' do
    it 'uses the base url from the environment variable' do
      stub_const('Whatsapp::Providers::WhatsappBaileysService::DEFAULT_URL', 'http://test.com')
      whatsapp_channel.update!(provider_config: {})

      expect(service.send(:provider_url)).to eq('http://test.com')
    end
  end

  context 'when environment variable BAILEYS_PROVIDER_DEFAULT_API_KEY is set' do
    it 'uses the API key from the environment variable' do
      stub_const('Whatsapp::Providers::WhatsappBaileysService::DEFAULT_API_KEY', 'key')
      whatsapp_channel.update!(provider_config: {})

      expect(service.send(:api_key)).to eq('key')
    end
  end

  def stub_headers(channel)
    {
      'Content-Type' => 'application/json',
      'x-api-key' => channel.provider_config['api_key']
    }
  end
end
