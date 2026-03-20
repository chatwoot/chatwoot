require 'rails_helper'

describe Whatsapp::Providers::WhatsappBaileysService do
  subject(:service) { described_class.new(whatsapp_channel: whatsapp_channel) }

  let(:whatsapp_channel) { create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false) }
  let(:message) { create(:message, inbox: whatsapp_channel.inbox, source_id: 'msg_123', content_attributes: { external_created_at: 123 }) }

  let(:test_send_phone_number) { '551187654321' }
  let(:test_send_jid) { '551187654321@s.whatsapp.net' }

  before do
    stub_const('Whatsapp::Providers::WhatsappBaileysService::DEFAULT_CLIENT_NAME', 'chatwoot-test')
  end

  describe '.status' do
    context 'when DEFAULT_URL or DEFAULT_API_KEY are missing' do
      it 'raises ProviderUnavailableError when DEFAULT_URL is blank' do
        stub_const('Whatsapp::Providers::WhatsappBaileysService::DEFAULT_URL', '')
        stub_const('Whatsapp::Providers::WhatsappBaileysService::DEFAULT_API_KEY', 'test_key')

        expect do
          described_class.status
        end.to raise_error(Whatsapp::Providers::WhatsappBaileysService::ProviderUnavailableError,
                           'Missing BAILEYS_PROVIDER_DEFAULT_URL or BAILEYS_PROVIDER_DEFAULT_API_KEY setup')
      end

      it 'raises ProviderUnavailableError when DEFAULT_API_KEY is blank' do
        stub_const('Whatsapp::Providers::WhatsappBaileysService::DEFAULT_URL', 'http://test.com')
        stub_const('Whatsapp::Providers::WhatsappBaileysService::DEFAULT_API_KEY', '')

        expect do
          described_class.status
        end.to raise_error(Whatsapp::Providers::WhatsappBaileysService::ProviderUnavailableError,
                           'Missing BAILEYS_PROVIDER_DEFAULT_URL or BAILEYS_PROVIDER_DEFAULT_API_KEY setup')
      end

      it 'raises ProviderUnavailableError when both are blank' do
        stub_const('Whatsapp::Providers::WhatsappBaileysService::DEFAULT_URL', nil)
        stub_const('Whatsapp::Providers::WhatsappBaileysService::DEFAULT_API_KEY', nil)

        expect do
          described_class.status
        end.to raise_error(Whatsapp::Providers::WhatsappBaileysService::ProviderUnavailableError,
                           'Missing BAILEYS_PROVIDER_DEFAULT_URL or BAILEYS_PROVIDER_DEFAULT_API_KEY setup')
      end
    end

    context 'when DEFAULT_URL and DEFAULT_API_KEY are present' do
      before do
        stub_const('Whatsapp::Providers::WhatsappBaileysService::DEFAULT_URL', 'http://test.com')
        stub_const('Whatsapp::Providers::WhatsappBaileysService::DEFAULT_API_KEY', 'test_key')
      end

      context 'when response is successful' do
        it 'returns the status response with symbolized keys' do
          stub_request(:get, 'http://test.com/status')
            .with(headers: { 'x-api-key' => 'test_key' })
            .to_return(
              status: 200,
              headers: { 'Content-Type' => 'application/json' },
              body: { packageInfo: { version: '1.0.0' } }.to_json
            )

          result = described_class.status

          expect(result).to eq({ packageInfo: { version: '1.0.0' } })
        end
      end

      context 'when response is unsuccessful' do
        it 'logs the error and raises ProviderUnavailableError' do
          stub_request(:get, 'http://test.com/status')
            .with(headers: { 'x-api-key' => 'test_key' })
            .to_return(
              status: 500,
              body: 'Internal Server Error',
              headers: {}
            )

          allow(Rails.logger).to receive(:error)

          expect do
            described_class.status
          end.to raise_error(Whatsapp::Providers::WhatsappBaileysService::ProviderUnavailableError, 'Baileys API is unavailable')

          expect(Rails.logger).to have_received(:error).with('Internal Server Error')
        end
      end
    end
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
              includeMedia: false,
              groupsEnabled: described_class.groups_enabled?
            }.to_json
          )
          .to_return(status: 200)

        response = service.setup_channel_provider

        expect(response).to be(true)
      end
    end

    context 'when response is unsuccessful' do
      it 'raises ProviderUnavailableError and logs the error' do
        stub_request(:post, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}")
          .with(
            headers: stub_headers(whatsapp_channel),
            body: {
              clientName: 'chatwoot-test',
              webhookUrl: whatsapp_channel.inbox.callback_webhook_url,
              webhookVerifyToken: whatsapp_channel.provider_config['webhook_verify_token'],
              includeMedia: false,
              groupsEnabled: described_class.groups_enabled?
            }.to_json
          )
          .to_return(
            status: 400,
            body: 'error message',
            headers: {}
          )

        allow(Rails.logger).to receive(:error)

        expect do
          service.setup_channel_provider
        end.to raise_error(Whatsapp::Providers::WhatsappBaileysService::ProviderUnavailableError)

        expect(Rails.logger).to have_received(:error).with('error message').twice
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
      it 'raises ProviderUnavailableError and logs the error' do
        # Stub the failing request
        stub_request(:delete, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}")
          .with(headers: stub_headers(whatsapp_channel))
          .to_return(
            status: 400,
            body: 'error message',
            headers: {}
          )

        # Stub the reconnection attempt
        stub_request(:post, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}")
          .to_return(status: 200)

        allow(Rails.logger).to receive(:error)

        expect do
          service.disconnect_channel_provider
        end.to raise_error(Whatsapp::Providers::WhatsappBaileysService::ProviderUnavailableError)

        expect(Rails.logger).to have_received(:error).with('error message')
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

    context 'when message is input_csat' do
      before do
        allow(message).to receive(:outgoing_content).and_return('Please rate us http://example.com/survey')
        message.content_type = :input_csat
      end

      it 'sends the message with survey url' do
        stub_request(:post, request_path)
          .with(
            headers: stub_headers(whatsapp_channel),
            body: {
              jid: test_send_jid,
              messageContent: { text: 'Please rate us http://example.com/survey' }
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

    context 'when message is a reply to another message' do
      let(:inbox) { whatsapp_channel.inbox }
      let(:account_user) { create(:account_user, account: inbox.account) }
      let(:contact) { create(:contact, account: inbox.account, name: 'John Doe', phone_number: "+#{test_send_phone_number}") }
      let(:conversation) do
        contact_inbox = create(:contact_inbox, inbox: inbox, contact: contact, source_id: test_send_phone_number)
        create(:conversation, inbox: inbox, contact_inbox: contact_inbox)
      end

      it 'sends text reply to outgoing message with quotedMessage' do
        original_message = create(:message, inbox: inbox, conversation: conversation, sender: account_user,
                                            message_type: 'outgoing', source_id: 'original_msg_123', content: 'Original text')
        reply_message = create(:message, inbox: inbox, conversation: conversation, sender: account_user,
                                         content: 'Reply text', content_attributes: { in_reply_to_external_id: original_message.source_id })

        stub_request(:post, request_path)
          .with(
            headers: stub_headers(whatsapp_channel),
            body: {
              jid: test_send_jid,
              messageContent: {
                text: 'Reply text',
                quotedMessage: {
                  key: {
                    id: 'original_msg_123',
                    remoteJid: test_send_jid,
                    fromMe: true
                  },
                  message: { conversation: 'Original text' }
                }
              }
            }.to_json
          )
          .to_return(
            status: 200,
            headers: { 'Content-Type' => 'application/json' },
            body: result_body.to_json
          )

        result = service.send_message(test_send_phone_number, reply_message)

        expect(result).to eq('msg_123')
      end

      it 'sends text reply to incoming message with quotedMessage' do
        original_message = create(:message, inbox: inbox, conversation: conversation, sender: contact,
                                            message_type: 'incoming', source_id: 'incoming_msg_456', content: 'Incoming text')
        reply_message = create(:message, inbox: inbox, conversation: conversation, sender: account_user,
                                         content: 'Reply to incoming', content_attributes: { in_reply_to_external_id: original_message.source_id })

        stub_request(:post, request_path)
          .with(
            headers: stub_headers(whatsapp_channel),
            body: {
              jid: test_send_jid,
              messageContent: {
                text: 'Reply to incoming',
                quotedMessage: {
                  key: {
                    id: 'incoming_msg_456',
                    remoteJid: test_send_jid,
                    fromMe: false
                  },
                  message: { conversation: 'Incoming text' }
                }
              }
            }.to_json
          )
          .to_return(
            status: 200,
            headers: { 'Content-Type' => 'application/json' },
            body: result_body.to_json
          )

        result = service.send_message(test_send_phone_number, reply_message)

        expect(result).to eq('msg_123')
      end

      it 'sends reply to message with image attachment' do
        original_message = create(:message, inbox: inbox, conversation: conversation, sender: contact,
                                            message_type: 'incoming', source_id: 'image_msg_789', content: 'Check this image')
        original_message.attachments.create!(account_id: original_message.account_id, file_type: 'image',
                                             file: { io: StringIO.new('fake'), filename: 'image.png' })

        reply_message = create(:message, inbox: inbox, conversation: conversation, sender: account_user,
                                         content: 'Nice image!', content_attributes: { in_reply_to_external_id: original_message.source_id })

        stub_request(:post, request_path)
          .with(
            headers: stub_headers(whatsapp_channel),
            body: {
              jid: test_send_jid,
              messageContent: {
                text: 'Nice image!',
                quotedMessage: {
                  key: {
                    id: 'image_msg_789',
                    remoteJid: test_send_jid,
                    fromMe: false
                  },
                  message: { imageMessage: { caption: 'Check this image' } }
                }
              }
            }.to_json
          )
          .to_return(
            status: 200,
            headers: { 'Content-Type' => 'application/json' },
            body: result_body.to_json
          )

        result = service.send_message(test_send_phone_number, reply_message)

        expect(result).to eq('msg_123')
      end

      it 'sends message without quotedMessage when in_reply_to_external_id is blank' do
        regular_message = create(:message, inbox: inbox, conversation: conversation, sender: account_user, content: 'Regular message')

        stub_request(:post, request_path)
          .with(
            headers: stub_headers(whatsapp_channel),
            body: {
              jid: test_send_jid,
              messageContent: { text: 'Regular message' }
            }.to_json
          )
          .to_return(
            status: 200,
            headers: { 'Content-Type' => 'application/json' },
            body: result_body.to_json
          )

        result = service.send_message(test_send_phone_number, regular_message)

        expect(result).to eq('msg_123')
      end
    end

    context 'when recipient is a group' do
      let(:group_jid) { '123456789123456789@g.us' }

      it 'uses the group JID as-is without transformation' do
        stub_request(:post, request_path)
          .with(
            headers: stub_headers(whatsapp_channel),
            body: {
              jid: group_jid,
              messageContent: { text: message.content }
            }.to_json
          )
          .to_return(
            status: 200,
            headers: { 'Content-Type' => 'application/json' },
            body: result_body.to_json
          )

        result = service.send_message(group_jid, message)

        expect(result).to eq('msg_123')
      end
    end

    context 'when request is unsuccessful' do
      it 'raises ProviderUnavailableError' do
        stub_request(:post, request_path)
          .to_return(
            status: 400,
            headers: { 'Content-Type' => 'application/json' },
            body: result_body.to_json
          )

        # Stub the reconnection attempt
        stub_request(:post, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}")
          .to_return(status: 200)

        expect do
          service.send_message(test_send_phone_number, message)
        end.to raise_error(Whatsapp::Providers::WhatsappBaileysService::ProviderUnavailableError)
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
    end
  end

  describe '#read_messages' do
    it 'send read messages request' do
      stub_request(:post, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}/read-messages")
        .with(
          headers: stub_headers(whatsapp_channel),
          body: { keys: [{ id: message.source_id, remoteJid: test_send_jid, fromMe: false }] }.to_json
        ).to_return(status: 200, body: '', headers: {})

      result = service.read_messages([message], recipient_id: test_send_phone_number)

      expect(result).to be(true)
    end

    context 'when request is unsuccessful' do
      it 'raises ProviderUnavailableError' do
        stub_request(:post, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}/read-messages")
          .with(
            headers: stub_headers(whatsapp_channel),
            body: { keys: [{ id: message.source_id, remoteJid: test_send_jid, fromMe: false }] }.to_json
          ).to_return(status: 400, body: 'error message', headers: {})

        # Stub the reconnection attempt
        stub_request(:post, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}")
          .to_return(status: 200)

        expect do
          service.read_messages([message], recipient_id: test_send_phone_number)
        end.to raise_error(Whatsapp::Providers::WhatsappBaileysService::ProviderUnavailableError)
      end
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

    context 'when request is unsuccessful' do
      it 'raises ProviderUnavailableError' do
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
          ).to_return(status: 400, body: 'error message', headers: {})

        # Stub the reconnection attempt
        stub_request(:post, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}")
          .to_return(status: 200)

        expect do
          service.unread_message(test_send_phone_number, message)
        end.to raise_error(Whatsapp::Providers::WhatsappBaileysService::ProviderUnavailableError)
      end
    end
  end

  describe '#received_messages' do
    it 'send received messages request' do
      stub_request(:post, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}/send-receipts")
        .with(
          headers: stub_headers(whatsapp_channel),
          body: {
            keys: [{ id: message.source_id, remoteJid: test_send_jid, fromMe: false }]
          }.to_json
        ).to_return(status: 200)

      result = service.received_messages(test_send_phone_number, [message])

      expect(result).to be(true)
    end

    context 'when request is unsuccessful' do
      it 'raises ProviderUnavailableError' do
        stub_request(:post, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}/send-receipts")
          .with(
            headers: stub_headers(whatsapp_channel),
            body: {
              keys: [{ id: message.source_id, remoteJid: test_send_jid, fromMe: false }]
            }.to_json
          ).to_return(status: 400, body: 'error message', headers: {})

        # Stub the reconnection attempt
        stub_request(:post, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}")
          .to_return(status: 200)

        expect do
          service.received_messages(test_send_phone_number, [message])
        end.to raise_error(Whatsapp::Providers::WhatsappBaileysService::ProviderUnavailableError)
      end
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

      service.toggle_typing_status(Events::Types::CONVERSATION_TYPING_ON, recipient_id: test_send_phone_number)

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

      service.toggle_typing_status(Events::Types::CONVERSATION_RECORDING, recipient_id: test_send_phone_number)

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

      service.toggle_typing_status(Events::Types::CONVERSATION_TYPING_OFF, recipient_id: test_send_phone_number)

      expect(request).to have_been_requested
    end

    context 'when request is unsuccessful' do
      it 'raises ProviderUnavailableError and logs the error' do
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

        stub_request(:post, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}")
          .to_return(status: 200)

        allow(Rails.logger).to receive(:error)

        expect do
          service.toggle_typing_status(Events::Types::CONVERSATION_TYPING_ON, recipient_id: test_send_phone_number)
        end.to raise_error(Whatsapp::Providers::WhatsappBaileysService::ProviderUnavailableError)

        expect(Rails.logger).to have_received(:error).with('error message')
      end
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

    context 'when request is unsuccessful' do
      it 'raises ProviderUnavailableError and logs the error' do
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

        stub_request(:post, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}")
          .to_return(status: 200)

        allow(Rails.logger).to receive(:error)

        expect do
          service.update_presence('online')
        end.to raise_error(Whatsapp::Providers::WhatsappBaileysService::ProviderUnavailableError)

        expect(Rails.logger).to have_received(:error).with('error message')
      end
    end
  end

  describe '#on_whatsapp' do
    let(:request_path) { "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}/on-whatsapp" }
    let(:phone_number) { '+123456789' }

    context 'when response is successful' do
      it 'requests whatsapp check' do
        stub_request(:post, request_path)
          .with(headers: stub_headers(whatsapp_channel), body: { jids: ["#{phone_number.delete('+')}@s.whatsapp.net"] }.to_json)
          .to_return(
            status: 200,
            headers: { 'Content-Type' => 'application/json' },
            body: { data: [{ jid: "#{phone_number.delete('+')}@s.whatsapp.net", exists: true }] }.to_json
          )

        response = service.on_whatsapp(phone_number)

        expect(response).to eq({ 'jid' => "#{phone_number.delete('+')}@s.whatsapp.net", 'exists' => true })
      end

      it 'returns default check response' do
        stub_request(:post, request_path)
          .with(headers: stub_headers(whatsapp_channel), body: { jids: ["#{phone_number.delete('+')}@s.whatsapp.net"] }.to_json)
          .to_return(
            status: 200,
            headers: { 'Content-Type' => 'application/json' },
            body: { data: [] }.to_json
          )

        response = service.on_whatsapp(phone_number)

        expect(response).to eq({ 'jid' => "#{phone_number.delete('+')}@s.whatsapp.net", 'exists' => false })
      end
    end

    context 'when response is an array instead of a hash' do
      it 'handles the array response correctly' do
        stub_request(:post, request_path)
          .with(headers: stub_headers(whatsapp_channel), body: { jids: ["#{phone_number.delete('+')}@s.whatsapp.net"] }.to_json)
          .to_return(
            status: 200,
            headers: { 'Content-Type' => 'application/json' },
            body: [{ jid: "#{phone_number.delete('+')}@s.whatsapp.net", exists: true }].to_json
          )

        response = service.on_whatsapp(phone_number)

        expect(response).to eq({ 'jid' => "#{phone_number.delete('+')}@s.whatsapp.net", 'exists' => true })
      end

      it 'returns default check response when array is empty' do
        stub_request(:post, request_path)
          .with(headers: stub_headers(whatsapp_channel), body: { jids: ["#{phone_number.delete('+')}@s.whatsapp.net"] }.to_json)
          .to_return(
            status: 200,
            headers: { 'Content-Type' => 'application/json' },
            body: [].to_json
          )

        response = service.on_whatsapp(phone_number)

        expect(response).to eq({ 'jid' => "#{phone_number.delete('+')}@s.whatsapp.net", 'exists' => false })
      end
    end

    context 'when response is unsuccessful' do
      it 'raises ProviderUnavailableError and logs the error' do
        stub_request(:post, request_path)
          .with(headers: stub_headers(whatsapp_channel), body: { jids: ["#{phone_number.delete('+')}@s.whatsapp.net"] }.to_json)
          .to_return(
            status: 400,
            body: 'error message',
            headers: {}
          )

        stub_request(:post, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}")
          .to_return(status: 200)

        allow(Rails.logger).to receive(:error)

        expect do
          service.on_whatsapp(phone_number)
        end.to raise_error(Whatsapp::Providers::WhatsappBaileysService::ProviderUnavailableError)

        expect(Rails.logger).to have_received(:error).with('error message')
      end
    end
  end

  describe '#delete_message' do
    let(:request_path) { "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}/messages" }
    let(:outgoing_message) { create(:message, inbox: whatsapp_channel.inbox, source_id: 'msg_456', message_type: :outgoing) }
    let(:incoming_message) { create(:message, inbox: whatsapp_channel.inbox, source_id: 'msg_789', message_type: :incoming) }

    context 'when deleting an outgoing message' do
      it 'sends delete request with fromMe true' do
        stub_request(:delete, request_path)
          .with(
            headers: stub_headers(whatsapp_channel),
            body: {
              jid: test_send_jid,
              key: {
                id: outgoing_message.source_id,
                remoteJid: test_send_jid,
                fromMe: true
              }
            }.to_json
          )
          .to_return(status: 200, body: '{}')

        result = service.delete_message(test_send_phone_number, outgoing_message)

        expect(result).to be(true)
      end
    end

    context 'when deleting an incoming message' do
      it 'sends delete request with fromMe false' do
        stub_request(:delete, request_path)
          .with(
            headers: stub_headers(whatsapp_channel),
            body: {
              jid: test_send_jid,
              key: {
                id: incoming_message.source_id,
                remoteJid: test_send_jid,
                fromMe: false
              }
            }.to_json
          )
          .to_return(status: 200, body: '{}')

        result = service.delete_message(test_send_phone_number, incoming_message)

        expect(result).to be(true)
      end
    end

    context 'when response is unsuccessful' do
      it 'raises ProviderUnavailableError and logs the error' do
        stub_request(:delete, request_path)
          .with(headers: stub_headers(whatsapp_channel))
          .to_return(status: 400, body: 'error message')

        stub_request(:post, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}")
          .to_return(status: 200)

        allow(Rails.logger).to receive(:error)

        expect do
          service.delete_message(test_send_phone_number, outgoing_message)
        end.to raise_error(Whatsapp::Providers::WhatsappBaileysService::ProviderUnavailableError)

        expect(Rails.logger).to have_received(:error).with('error message')
      end
    end
  end

  context 'when managing group messages with participant' do # rubocop:disable RSpec/MultipleMemoizedHelpers
    let(:inbox) { whatsapp_channel.inbox }
    let(:account_user) { create(:account_user, account: inbox.account) }
    let(:group_jid) { '123456789123456789@g.us' }
    let(:participant_lid) { '1111111@lid' }
    let(:group_contact) { create(:contact, account: inbox.account, name: 'Test Group', identifier: group_jid, group_type: :group) }
    let(:sender_contact) do
      create(:contact, account: inbox.account, name: 'Participant', identifier: participant_lid, phone_number: '+5511999999999')
    end
    let(:conversation) do
      contact_inbox = create(:contact_inbox, inbox: inbox, contact: group_contact, source_id: group_jid.split('@').first)
      create(:conversation, inbox: inbox, contact_inbox: contact_inbox, contact: group_contact, group_type: :group)
    end
    let(:incoming_group_message) do
      create(:message, inbox: inbox, conversation: conversation, sender: sender_contact,
                       message_type: 'incoming', source_id: 'group_msg_123', content: 'Hello',
                       content_attributes: { external_created_at: 123 })
    end
    let(:outgoing_group_message) do
      create(:message, inbox: inbox, conversation: conversation, sender: account_user,
                       message_type: 'outgoing', source_id: 'group_msg_456', content: 'Reply')
    end
    let(:send_message_path) { "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}/send-message" }
    let(:result_body) { { 'data' => { 'key' => { 'id' => 'msg_123' } } } }

    describe '#send_message' do # rubocop:disable RSpec/MultipleMemoizedHelpers
      it 'includes participant in quotedMessage key when replying to incoming message' do
        original_message = create(:message, inbox: inbox, conversation: conversation, sender: sender_contact,
                                            message_type: 'incoming', source_id: 'incoming_group_msg', content: 'Hello')
        reply_message = create(:message, inbox: inbox, conversation: conversation, sender: account_user,
                                         content: 'World!',
                                         content_attributes: { in_reply_to_external_id: original_message.source_id })
        stub_request(:post, send_message_path)
          .with(
            headers: stub_headers(whatsapp_channel),
            body: {
              jid: group_jid,
              messageContent: {
                text: 'World!',
                quotedMessage: {
                  key: { id: 'incoming_group_msg', remoteJid: group_jid, fromMe: false, participant: participant_lid },
                  message: { conversation: 'Hello' }
                }
              }
            }.to_json
          )
          .to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: result_body.to_json)

        result = service.send_message(group_jid, reply_message)

        expect(result).to eq('msg_123')
      end

      it 'does not include participant when replying to outgoing message' do
        original_message = create(:message, inbox: inbox, conversation: conversation, sender: account_user,
                                            message_type: 'outgoing', source_id: 'outgoing_group_msg', content: 'Hello')
        reply_message = create(:message, inbox: inbox, conversation: conversation, sender: account_user,
                                         content: 'World!',
                                         content_attributes: { in_reply_to_external_id: original_message.source_id })
        stub_request(:post, send_message_path)
          .with(
            headers: stub_headers(whatsapp_channel),
            body: {
              jid: group_jid,
              messageContent: {
                text: 'World!',
                quotedMessage: {
                  key: { id: 'outgoing_group_msg', remoteJid: group_jid, fromMe: true },
                  message: { conversation: 'Hello' }
                }
              }
            }.to_json
          )
          .to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: result_body.to_json)

        result = service.send_message(group_jid, reply_message)

        expect(result).to eq('msg_123')
      end

      it 'includes participant in reaction key when reacting to incoming message' do
        original_message = create(:message, inbox: inbox, conversation: conversation, sender: sender_contact,
                                            message_type: 'incoming', source_id: 'react_group_msg', content: 'Nice')
        reaction = create(:message, inbox: inbox, conversation: conversation, sender: account_user, content: '👍',
                                    content_attributes: { is_reaction: true, in_reply_to: original_message.id })
        stub_request(:post, send_message_path)
          .with(
            headers: stub_headers(whatsapp_channel),
            body: {
              jid: group_jid,
              messageContent: {
                react: {
                  key: { id: original_message.source_id, remoteJid: group_jid, fromMe: false, participant: participant_lid },
                  text: '👍'
                }
              }
            }.to_json
          )
          .to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: result_body.to_json)

        result = service.send_message(group_jid, reaction)

        expect(result).to eq('msg_123')
      end

      it 'does not include participant in reaction key when reacting to outgoing message' do
        original_message = create(:message, inbox: inbox, conversation: conversation, sender: account_user,
                                            message_type: 'outgoing', source_id: 'react_out_msg', content: 'Sent')
        reaction = create(:message, inbox: inbox, conversation: conversation, sender: account_user, content: '❤️',
                                    content_attributes: { is_reaction: true, in_reply_to: original_message.id })
        stub_request(:post, send_message_path)
          .with(
            headers: stub_headers(whatsapp_channel),
            body: {
              jid: group_jid,
              messageContent: {
                react: {
                  key: { id: original_message.source_id, remoteJid: group_jid, fromMe: true },
                  text: '❤️'
                }
              }
            }.to_json
          )
          .to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: result_body.to_json)

        result = service.send_message(group_jid, reaction)

        expect(result).to eq('msg_123')
      end
    end

    describe '#read_messages' do # rubocop:disable RSpec/MultipleMemoizedHelpers
      it 'includes participant for incoming group messages' do
        stub_request(:post, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}/read-messages")
          .with(
            headers: stub_headers(whatsapp_channel),
            body: { keys: [{ id: incoming_group_message.source_id, remoteJid: group_jid, fromMe: false, participant: participant_lid }] }.to_json
          ).to_return(status: 200)

        result = service.read_messages([incoming_group_message], recipient_id: group_jid)

        expect(result).to be(true)
      end

      it 'does not include participant for outgoing group messages' do
        stub_request(:post, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}/read-messages")
          .with(
            headers: stub_headers(whatsapp_channel),
            body: { keys: [{ id: outgoing_group_message.source_id, remoteJid: group_jid, fromMe: true }] }.to_json
          ).to_return(status: 200)

        result = service.read_messages([outgoing_group_message], recipient_id: group_jid)

        expect(result).to be(true)
      end
    end

    describe '#unread_message' do # rubocop:disable RSpec/MultipleMemoizedHelpers
      it 'includes participant for incoming group message' do
        stub_request(:post, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}/chat-modify")
          .with(
            headers: stub_headers(whatsapp_channel),
            body: {
              jid: group_jid,
              mod: {
                markRead: false,
                lastMessages: [{
                  key: { id: incoming_group_message.source_id, remoteJid: group_jid, fromMe: false, participant: participant_lid },
                  messageTimestamp: 123
                }]
              }
            }.to_json
          ).to_return(status: 200)

        result = service.unread_message(group_jid, incoming_group_message)

        expect(result).to be(true)
      end
    end

    describe '#received_messages' do # rubocop:disable RSpec/MultipleMemoizedHelpers
      it 'includes participant for incoming group messages' do
        stub_request(:post, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}/send-receipts")
          .with(
            headers: stub_headers(whatsapp_channel),
            body: { keys: [{ id: incoming_group_message.source_id, remoteJid: group_jid, fromMe: false, participant: participant_lid }] }.to_json
          ).to_return(status: 200)

        result = service.received_messages(group_jid, [incoming_group_message])

        expect(result).to be(true)
      end
    end

    describe '#delete_message' do # rubocop:disable RSpec/MultipleMemoizedHelpers
      it 'includes participant for incoming group message' do
        stub_request(:delete, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}/messages")
          .with(
            headers: stub_headers(whatsapp_channel),
            body: {
              jid: group_jid,
              key: { id: incoming_group_message.source_id, remoteJid: group_jid, fromMe: false, participant: participant_lid }
            }.to_json
          ).to_return(status: 200, body: '{}')

        result = service.delete_message(group_jid, incoming_group_message)

        expect(result).to be(true)
      end

      it 'does not include participant for outgoing group message' do
        stub_request(:delete, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}/messages")
          .with(
            headers: stub_headers(whatsapp_channel),
            body: {
              jid: group_jid,
              key: { id: outgoing_group_message.source_id, remoteJid: group_jid, fromMe: true }
            }.to_json
          ).to_return(status: 200, body: '{}')

        result = service.delete_message(group_jid, outgoing_group_message)

        expect(result).to be(true)
      end
    end

    describe '#edit_message' do # rubocop:disable RSpec/MultipleMemoizedHelpers
      it 'includes participant for incoming group message' do
        stub_request(:patch, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}/messages")
          .with(
            headers: stub_headers(whatsapp_channel),
            body: {
              jid: group_jid,
              key: { id: incoming_group_message.source_id, remoteJid: group_jid, fromMe: false, participant: participant_lid },
              messageContent: { text: 'Edited text' }
            }.to_json
          ).to_return(status: 200, body: '{}')

        result = service.edit_message(group_jid, incoming_group_message, 'Edited text')

        expect(result).to be(true)
      end

      it 'does not include participant for outgoing group message' do
        stub_request(:patch, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}/messages")
          .with(
            headers: stub_headers(whatsapp_channel),
            body: {
              jid: group_jid,
              key: { id: outgoing_group_message.source_id, remoteJid: group_jid, fromMe: true },
              messageContent: { text: 'Edited text' }
            }.to_json
          ).to_return(status: 200, body: '{}')

        result = service.edit_message(group_jid, outgoing_group_message, 'Edited text')

        expect(result).to be(true)
      end
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

  describe 'error handling' do
    describe '#handle_channel_error' do
      it 'updates provider connection to close' do
        whatsapp_channel.update!(provider_connection: { 'connection' => 'open' })

        stub_request(:post, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}")
          .with(
            headers: stub_headers(whatsapp_channel),
            body: {
              clientName: 'chatwoot-test',
              webhookUrl: whatsapp_channel.inbox.callback_webhook_url,
              webhookVerifyToken: whatsapp_channel.provider_config['webhook_verify_token'],
              includeMedia: false,
              groupsEnabled: described_class.groups_enabled?
            }.to_json
          )
          .to_return(status: 200)

        service.send(:handle_channel_error)

        expect(whatsapp_channel.reload.provider_connection['connection']).to eq('close')
      end

      it 'attempts to reconnect by calling setup_channel_provider' do
        stub_request(:post, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}")
          .with(
            headers: stub_headers(whatsapp_channel),
            body: {
              clientName: 'chatwoot-test',
              webhookUrl: whatsapp_channel.inbox.callback_webhook_url,
              webhookVerifyToken: whatsapp_channel.provider_config['webhook_verify_token'],
              includeMedia: false,
              groupsEnabled: described_class.groups_enabled?
            }.to_json
          )
          .to_return(status: 200)

        service.send(:handle_channel_error)

        expect(WebMock).to have_requested(:post, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}")
      end

      it 'logs error and does not raise when reconnection fails' do
        stub_request(:post, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}")
          .with(
            headers: stub_headers(whatsapp_channel),
            body: {
              clientName: 'chatwoot-test',
              webhookUrl: whatsapp_channel.inbox.callback_webhook_url,
              webhookVerifyToken: whatsapp_channel.provider_config['webhook_verify_token'],
              includeMedia: false,
              groupsEnabled: described_class.groups_enabled?
            }.to_json
          )
          .to_return(status: 400, body: 'reconnection failed')

        allow(Rails.logger).to receive(:error)

        expect { service.send(:handle_channel_error) }.not_to raise_error

        expect(Rails.logger).to have_received(:error).with(/Failed to reconnect channel after error/)
      end

      it 'prevents infinite loop with @handling_error flag' do
        service.instance_variable_set(:@handling_error, true)

        expect(HTTParty).not_to receive(:post)

        service.send(:handle_channel_error)

        expect(whatsapp_channel.reload.provider_connection['connection']).to eq('close')
      end
    end

    describe 'error handling wrapper' do
      context 'when send_message fails' do
        it 'calls handle_channel_error and re-raises the error' do
          stub_request(:post, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}/send-message")
            .to_return(status: 500, body: 'server error')

          stub_request(:post, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}")
            .to_return(status: 200)

          whatsapp_channel.update!(provider_connection: { 'connection' => 'open' })

          expect do
            service.send_message(test_send_phone_number, message)
          end.to raise_error(Whatsapp::Providers::WhatsappBaileysService::ProviderUnavailableError)

          expect(whatsapp_channel.reload.provider_connection['connection']).to eq('close')

          expect(WebMock).to have_requested(:post, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}")
        end
      end

      context 'when setup_channel_provider fails' do
        it 'calls handle_channel_error and re-raises the error' do
          stub_request(:post, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}")
            .to_return(status: 500, body: 'server error')

          whatsapp_channel.update!(provider_connection: { 'connection' => 'open' })
          allow(Rails.logger).to receive(:error)

          expect do
            service.setup_channel_provider
          end.to raise_error(Whatsapp::Providers::WhatsappBaileysService::ProviderUnavailableError)

          expect(whatsapp_channel.reload.provider_connection['connection']).to eq('close')

          expect(Rails.logger).to have_received(:error).with(/Failed to reconnect channel after error/)
        end
      end

      context 'when toggle_typing_status fails' do
        it 'calls handle_channel_error and re-raises the error' do
          stub_request(:patch, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}/presence")
            .to_return(status: 500, body: 'server error')

          stub_request(:post, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}")
            .to_return(status: 200)

          whatsapp_channel.update!(provider_connection: { 'connection' => 'open' })

          expect do
            service.toggle_typing_status(Events::Types::CONVERSATION_TYPING_ON, recipient_id: test_send_phone_number)
          end.to raise_error(Whatsapp::Providers::WhatsappBaileysService::ProviderUnavailableError)

          expect(whatsapp_channel.reload.provider_connection['connection']).to eq('close')

          expect(WebMock).to have_requested(:post, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}")
        end
      end
    end
  end

  describe '#get_profile_pic' do
    let(:test_jid) { '551187654321@s.whatsapp.net' }

    context 'when response is successful' do
      it 'returns the profile picture URL data' do
        stub_request(:get, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}/profile-picture-url")
          .with(
            headers: stub_headers(whatsapp_channel),
            query: { jid: test_jid }
          )
          .to_return(
            status: 200,
            body: { data: { profilePictureUrl: 'https://pps.whatsapp.net/v/t61.24694-24/avatar.jpg', jid: test_jid } }.to_json
          )

        result = service.get_profile_pic(test_jid)

        expect(result).to eq({
                               'data' => {
                                 'profilePictureUrl' => 'https://pps.whatsapp.net/v/t61.24694-24/avatar.jpg',
                                 'jid' => test_jid
                               }
                             })
      end
    end

    context 'when response fails' do
      it 'returns nil when profile picture not found (404)' do
        stub_request(:get, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}/profile-picture-url")
          .with(
            headers: stub_headers(whatsapp_channel),
            query: { jid: test_jid }
          )
          .to_return(
            status: 404,
            body: { error: 'Profile picture not found' }.to_json
          )

        result = service.get_profile_pic(test_jid)

        expect(result).to be_nil
      end
    end
  end

  describe '#group_metadata' do
    let(:group_jid) { '123456789123456789@g.us' }

    it 'returns symbolized group metadata on success' do
      stub_request(:get, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}/group-metadata")
        .with(headers: stub_headers(whatsapp_channel), query: { jid: group_jid })
        .to_return(
          status: 200,
          body: {
            subject: 'Test Group',
            participants: [
              { id: '111@lid', phoneNumber: '5511911111111@s.whatsapp.net', admin: 'admin' },
              { id: '222@lid', phoneNumber: '5511922222222@s.whatsapp.net', admin: nil }
            ]
          }.to_json
        )

      result = service.group_metadata(group_jid)

      expect(result[:subject]).to eq('Test Group')
      expect(result[:participants].length).to eq(2)
      expect(result[:participants].first[:admin]).to eq('admin')
    end

    it 'raises ProviderUnavailableError when the API returns an error' do
      stub_request(:get, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}/group-metadata")
        .with(headers: stub_headers(whatsapp_channel), query: { jid: group_jid })
        .to_return(status: 404, body: { error: 'Group not found' }.to_json)

      stub_request(:post, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}")
        .to_return(status: 200)

      expect do
        service.group_metadata(group_jid)
      end.to raise_error(Whatsapp::Providers::WhatsappBaileysService::ProviderUnavailableError)
    end
  end

  describe '#update_group_participants' do
    let(:group_jid) { '123456789@g.us' }
    let(:participant_jid) { '5511999999999@s.whatsapp.net' }
    let(:request_path) { "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}/group-participants" }

    it 'sends a POST request per participant with singular participant key' do
      stub_request(:post, request_path)
        .with(headers: stub_headers(whatsapp_channel), body: { jid: group_jid, participant: participant_jid, action: 'add' }.to_json)
        .to_return(status: 200)

      service.update_group_participants(group_jid, [participant_jid], 'add')

      expect(WebMock).to have_requested(:post, request_path)
        .with(body: { jid: group_jid, participant: participant_jid, action: 'add' }.to_json).once
    end

    it 'makes one call per participant when given multiple' do
      jid_a = '111@s.whatsapp.net'
      jid_b = '222@s.whatsapp.net'

      stub_request(:post, request_path).to_return(status: 200)

      service.update_group_participants(group_jid, [jid_a, jid_b], 'remove')

      expect(WebMock).to have_requested(:post, request_path)
        .with(body: { jid: group_jid, participant: jid_a, action: 'remove' }.to_json).once
      expect(WebMock).to have_requested(:post, request_path)
        .with(body: { jid: group_jid, participant: jid_b, action: 'remove' }.to_json).once
    end

    it 'raises ProviderUnavailableError on failure' do
      stub_request(:post, request_path).to_return(status: 400, body: 'error')
      stub_request(:post, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}")
        .to_return(status: 200)
      allow(Rails.logger).to receive(:error)

      expect do
        service.update_group_participants(group_jid, [participant_jid], 'add')
      end.to raise_error(Whatsapp::Providers::WhatsappBaileysService::ProviderUnavailableError)
    end
  end

  describe '#group_invite_code' do
    let(:group_jid) { '123456789@g.us' }
    let(:request_path) { "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}/group-invite-code" }

    it 'returns the inviteCode from response data' do
      stub_request(:get, request_path)
        .with(headers: stub_headers(whatsapp_channel), query: { jid: group_jid })
        .to_return(status: 200, headers: { 'Content-Type' => 'application/json' },
                   body: { data: { jid: group_jid, inviteCode: 'ABC123' } }.to_json)

      result = service.group_invite_code(group_jid)

      expect(result).to eq('ABC123')
    end

    it 'raises ProviderUnavailableError on failure' do
      stub_request(:get, request_path)
        .with(query: { jid: group_jid })
        .to_return(status: 400, body: 'error')
      stub_request(:post, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}")
        .to_return(status: 200)
      allow(Rails.logger).to receive(:error)

      expect do
        service.group_invite_code(group_jid)
      end.to raise_error(Whatsapp::Providers::WhatsappBaileysService::ProviderUnavailableError)
    end
  end

  describe '#revoke_group_invite' do
    let(:group_jid) { '123456789@g.us' }
    let(:request_path) { "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}/group-revoke-invite" }

    it 'returns the inviteCode from response data' do
      stub_request(:post, request_path)
        .with(headers: stub_headers(whatsapp_channel), body: { jid: group_jid }.to_json)
        .to_return(status: 200, headers: { 'Content-Type' => 'application/json' },
                   body: { data: { jid: group_jid, inviteCode: 'NEW456' } }.to_json)

      result = service.revoke_group_invite(group_jid)

      expect(result).to eq('NEW456')
    end
  end

  describe '#group_join_requests' do
    let(:group_jid) { '123456789@g.us' }
    let(:request_path) do
      "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}/group-request-participants-list"
    end

    it 'sends GET to group-request-participants-list and returns data' do
      stub_request(:get, request_path)
        .with(headers: stub_headers(whatsapp_channel), query: { jid: group_jid })
        .to_return(status: 200, headers: { 'Content-Type' => 'application/json' },
                   body: { data: [{ jid: '999@s.whatsapp.net' }] }.to_json)

      result = service.group_join_requests(group_jid)

      expect(result).to eq([{ 'jid' => '999@s.whatsapp.net' }])
    end

    it 'returns empty array when data is nil' do
      stub_request(:get, request_path)
        .with(query: { jid: group_jid })
        .to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: {}.to_json)

      result = service.group_join_requests(group_jid)

      expect(result).to eq([])
    end
  end

  describe '#handle_group_join_requests' do
    let(:group_jid) { '123456789@g.us' }
    let(:participants) { ['999@s.whatsapp.net'] }
    let(:request_path) do
      "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}/group-request-participants-update"
    end

    it 'sends POST to group-request-participants-update with participants array' do
      stub_request(:post, request_path)
        .with(headers: stub_headers(whatsapp_channel),
              body: { jid: group_jid, participants: participants, action: 'approve' }.to_json)
        .to_return(status: 200)

      service.handle_group_join_requests(group_jid, participants, 'approve')

      expect(WebMock).to have_requested(:post, request_path)
        .with(body: { jid: group_jid, participants: participants, action: 'approve' }.to_json).once
    end
  end

  describe '#sync_group' do
    let(:group_contact) { create(:contact, account: whatsapp_channel.account, identifier: '123456789@g.us', name: 'Old Group Name') }
    let(:conversation) { create(:conversation, inbox: whatsapp_channel.inbox, contact: group_contact) }
    let(:base_url) { "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}" }
    let(:metadata) do
      {
        subject: 'Updated Group Name',
        desc: 'Group description',
        owner: '111@lid',
        ownerPn: '5511911111111',
        participants: [
          { id: '111@lid', phoneNumber: '5511911111111@s.whatsapp.net', admin: 'admin' },
          { id: '222@lid', phoneNumber: '5511922222222@s.whatsapp.net', admin: nil }
        ]
      }
    end

    before do
      stub_request(:get, "#{base_url}/group-invite-code")
        .with(headers: stub_headers(whatsapp_channel), query: { jid: group_contact.identifier })
        .to_return(status: 200, body: { code: 'ABC123' }.to_json)
      stub_request(:get, "#{base_url}/profile-picture-url")
        .with(headers: stub_headers(whatsapp_channel), query: { jid: group_contact.identifier })
        .to_return(status: 200, body: { data: { profilePictureUrl: nil } }.to_json)
      stub_request(:get, "#{base_url}/group-request-participants-list")
        .with(headers: stub_headers(whatsapp_channel), query: { jid: group_contact.identifier })
        .to_return(status: 200, body: [].to_json)
    end

    def stub_group_metadata(body)
      stub_request(:get, "#{base_url}/group-metadata")
        .with(headers: stub_headers(whatsapp_channel), query: { jid: group_contact.identifier })
        .to_return(status: 200, body: body.to_json)
    end

    def stub_participant_services(*contacts)
      allow(Whatsapp::ContactInboxConsolidationService).to receive(:new)
        .and_return(instance_double(Whatsapp::ContactInboxConsolidationService, perform: nil))

      contact_inboxes = contacts.map do |contact|
        create(:contact_inbox, inbox: whatsapp_channel.inbox, contact: contact)
      end

      allow(ContactInboxWithContactBuilder).to receive(:new)
        .and_return(*contact_inboxes.map { |ci| instance_double(ContactInboxWithContactBuilder, perform: ci) })

      stub_request(:get, %r{/profile-picture-url}).to_return(status: 200, body: {}.to_json)
    end

    it 'raises ProviderUnavailableError when metadata is blank' do
      stub_group_metadata({})
      stub_request(:post, base_url).to_return(status: 200)

      expect { service.sync_group(conversation) }.to raise_error(
        Whatsapp::Providers::WhatsappBaileysService::ProviderUnavailableError
      )
    end

    it 'updates group contact name and attributes from metadata' do
      stub_group_metadata(metadata.merge(participants: []))

      service.sync_group(conversation)

      group_contact.reload
      expect(group_contact.name).to eq('Updated Group Name')
      expect(group_contact.additional_attributes).to include('description' => 'Group description', 'owner' => '111@lid')
    end

    it 'creates group members with correct roles from participants' do
      admin_contact = create(:contact, account: whatsapp_channel.account)
      member_contact = create(:contact, account: whatsapp_channel.account)
      stub_group_metadata(metadata)
      stub_participant_services(admin_contact, member_contact)

      service.sync_group(conversation)

      expect(GroupMember.find_by(group_contact: group_contact, contact: admin_contact)).to have_attributes(role: 'admin', is_active: true)
      expect(GroupMember.find_by(group_contact: group_contact, contact: member_contact)).to have_attributes(role: 'member', is_active: true)
    end

    it 'deactivates members not present in the participant list' do
      absent_contact = create(:contact, account: whatsapp_channel.account)
      GroupMember.create!(group_contact: group_contact, contact: absent_contact, is_active: true)
      remaining_contact = create(:contact, account: whatsapp_channel.account)
      stub_group_metadata(metadata.merge(participants: [metadata[:participants].last]))
      stub_participant_services(remaining_contact)

      service.sync_group(conversation)

      expect(GroupMember.find_by(group_contact: group_contact, contact: absent_contact).is_active).to be false
      expect(GroupMember.find_by(group_contact: group_contact, contact: remaining_contact).is_active).to be true
    end
  end

  def stub_headers(channel)
    {
      'Content-Type' => 'application/json',
      'x-api-key' => channel.provider_config['api_key']
    }
  end
end
