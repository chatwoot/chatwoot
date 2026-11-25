require 'rails_helper'

describe Whatsapp::Providers::WhatsappBaileysService do
  subject(:service) { described_class.new(whatsapp_channel: whatsapp_channel) }

  # `cache_classes = false` in the test env lets Zeitwerk reload constants
  # between specs (controller specs commonly trigger this). After a reload,
  # the `described_class` captured when this file was loaded points at a
  # stale copy whose `::ProviderUnavailableError` constant no longer matches
  # the one raised by the real (currently-loaded) class, breaking
  # `raise_error(ProviderUnavailableError, ...)` matchers. Re-resolving the
  # constant on every example keeps the reference fresh.
  let(:described_class) { Whatsapp::Providers::WhatsappBaileysService } # rubocop:disable RSpec/DescribedClass
  let(:whatsapp_channel) { create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false) }
  let(:message) { create(:message, inbox: whatsapp_channel.inbox, source_id: 'msg_123', content_attributes: { external_created_at: 123 }) }
  let(:test_send_phone_number) { '551187654321' }
  let(:test_send_jid) { '551187654321@s.whatsapp.net' }

  before do
    stub_const('Whatsapp::Providers::WhatsappBaileysService::DEFAULT_CLIENT_NAME', 'chatwoot-test')
  end

  describe '.installed?' do
    it 'is false without a Baileys API configured' do
      stub_const('Whatsapp::Providers::WhatsappBaileysService::DEFAULT_URL', nil)

      expect(described_class.installed?).to be(false)
    end

    context 'with a Baileys API configured' do
      before do
        stub_const('Whatsapp::Providers::WhatsappBaileysService::DEFAULT_URL', 'http://test.com')
        stub_const('Whatsapp::Providers::WhatsappBaileysService::DEFAULT_API_KEY', 'test_key')
      end

      it 'is true when the API answers' do
        stub_request(:get, 'http://test.com/status').to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

        expect(described_class.installed?).to be(true)
      end

      it 'is false when the API errors' do
        stub_request(:get, 'http://test.com/status').to_return(status: 500)

        expect(described_class.installed?).to be(false)
      end

      it 'is false when the API does not answer in time, waiting the short timeout rather than a send one' do
        allow(HTTParty).to receive(:get).and_raise(Net::OpenTimeout)

        expect(described_class.installed?).to be(false)
        expect(HTTParty).to have_received(:get).with('http://test.com/status', hash_including(timeout: described_class::INSTALLATION_CHECK_TIMEOUT))
      end
    end
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
              groupsEnabled: described_class.groups_enabled?,
              syncFullHistory: false
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
              groupsEnabled: described_class.groups_enabled?,
              syncFullHistory: false
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

    context 'with a confirmed reconnect loop (quarantine strikes at the reset threshold)' do
      before do
        whatsapp_channel.update_provider_connection!(
          connection: 'reconnecting',
          quarantine: { strikes: 3, until: '2026-07-31T12:00:00.000Z' }
        )
      end

      it 'discards the stored session before requesting the new connection, so a QR is offered' do
        delete_stub = stub_request(:delete, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}")
                      .to_return(status: 200)
        post_stub = stub_request(:post, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}")
                    .to_return(status: 200)

        expect(service.setup_channel_provider).to be(true)

        expect(delete_stub).to have_been_requested
        expect(post_stub).to have_been_requested
      end
    end

    context 'with quarantine strikes below the reset threshold' do
      before do
        whatsapp_channel.update_provider_connection!(
          connection: 'reconnecting',
          quarantine: { strikes: 2, until: '2026-07-31T12:00:00.000Z' }
        )
      end

      it 'does not discard the stored session' do
        post_stub = stub_request(:post, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}")
                    .to_return(status: 200)

        expect(service.setup_channel_provider).to be(true)

        expect(post_stub).to have_been_requested
        expect(a_request(:delete, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}"))
          .not_to have_been_made
      end
    end

    context 'when the channel is open despite stale quarantine data' do
      before do
        whatsapp_channel.update_provider_connection!(
          connection: 'open',
          quarantine: { strikes: 5, until: '2026-07-31T12:00:00.000Z' }
        )
      end

      it 'never discards the stored session of an open channel' do
        post_stub = stub_request(:post, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}")
                    .to_return(status: 200)

        expect(service.setup_channel_provider).to be(true)

        expect(post_stub).to have_been_requested
        expect(a_request(:delete, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}"))
          .not_to have_been_made
      end
    end
  end

  describe '#import_session' do
    let(:import_url) do
      "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}/import-session"
    end
    let(:session) do
      {
        'noiseCandidates' => [{ 'private' => 'np0', 'public' => 'nb0' }],
        'identityKey' => { 'private' => 'ip', 'public' => 'ib' },
        'registrationId' => 42,
        'advSecretKey' => 'adv',
        'account' => { 'details' => 'd', 'accountSignatureKey' => 'ask', 'accountSignature' => 'as', 'deviceSignature' => 'ds' },
        'id' => '551101234567:12@s.whatsapp.net'
      }
    end

    context 'when response is successful' do
      it 'posts the session to the import endpoint' do
        request = stub_request(:post, import_url)
                  .with(
                    headers: stub_headers(whatsapp_channel),
                    body: {
                      session: session,
                      candidateIndex: 2,
                      clientName: 'chatwoot-test',
                      webhookUrl: whatsapp_channel.inbox.callback_webhook_url,
                      webhookVerifyToken: whatsapp_channel.provider_config['webhook_verify_token'],
                      includeMedia: false,
                      groupsEnabled: described_class.groups_enabled?,
                      syncFullHistory: false
                    }.to_json
                  )
                  .to_return(status: 202)

        expect(service.import_session(session: session, candidate_index: 2)).to be(true)
        expect(request).to have_been_requested
      end
    end

    context 'when response is unsuccessful' do
      it 'raises ProviderUnavailableError' do
        stub_request(:post, import_url).to_return(status: 409, body: 'conflict')
        allow(Rails.logger).to receive(:error)

        expect do
          service.import_session(session: session)
        end.to(raise_error { |error| expect(error.class.name).to eq(described_class::ProviderUnavailableError.name) })
      end
    end
  end

  describe '#disconnect_channel_provider' do
    let(:disconnect_url) { "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}" }

    context 'when the Baileys API responds successfully' do
      it 'returns true' do
        stub_request(:delete, disconnect_url)
          .with(headers: stub_headers(whatsapp_channel))
          .to_return(status: 200)

        expect(service.disconnect_channel_provider).to be(true)
      end
    end

    # The outcome has to travel. Swallowing it let the caller record the inbox as closed
    # while the session was still live — and for a send stall, whose only recovery is
    # re-pairing, that also cleared the warning that was the only thing telling anyone the
    # inbox was mute. The teardown callers that genuinely do not care rescue it themselves
    # (Channel::Whatsapp#disconnect_channel_provider), which is where that decision belongs.
    # 404 is the state being asked for, not a failure. Reporting it as one aborts a
    # provider conversion and leaves the modal offering Disconnect forever for a session
    # that is already gone.
    context 'when the session is already absent' do
      it 'returns true for HTTP 404' do
        stub_request(:delete, disconnect_url)
          .with(headers: stub_headers(whatsapp_channel))
          .to_return(status: 404, body: 'not found')

        expect(service.disconnect_channel_provider).to be(true)
      end
    end

    context 'when the Baileys API responds with an error status' do
      it 'raises and logs a warning for HTTP 500' do
        stub_request(:delete, disconnect_url)
          .with(headers: stub_headers(whatsapp_channel))
          .to_return(status: 500, body: 'baileys error')

        allow(Rails.logger).to receive(:warn)

        expect { service.disconnect_channel_provider }
          .to raise_error(Whatsapp::Session::Errors::ProviderUnavailable, /did not end the session/)
        expect(Rails.logger).to have_received(:warn).with(/disconnect_channel_provider non-success status=500/)
      end
    end

    context 'when the request itself fails' do
      it 'raises and logs a warning' do
        stub_request(:delete, disconnect_url)
          .with(headers: stub_headers(whatsapp_channel))
          .to_raise(Net::OpenTimeout)

        allow(Rails.logger).to receive(:warn)

        expect { service.disconnect_channel_provider }
          .to raise_error(Whatsapp::Session::Errors::ProviderUnavailable, /Could not reach the provider/)
        expect(Rails.logger).to have_received(:warn).with(/disconnect_channel_provider failed/)
      end

      it 'does not trigger the error recovery flow' do
        stub_request(:delete, disconnect_url)
          .with(headers: stub_headers(whatsapp_channel))
          .to_raise(Net::OpenTimeout)
        reconnect_request = stub_request(:post, disconnect_url)

        expect { service.disconnect_channel_provider }.to raise_error(Whatsapp::Session::Errors::Error)

        expect(reconnect_request).not_to have_been_requested
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
            body: send_message_body({
                                      jid: test_send_jid,
                                      messageContent: { text: 'Please rate us http://example.com/survey' }
                                    })
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
            body: send_message_body({
                                      jid: test_send_jid,
                                      messageContent: { fileName: 'image.png', caption: message.content, image: base64_image }
                                    })
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
            body: send_message_body({
                                      jid: test_send_jid,
                                      messageContent: { fileName: 'image.png', image: base64_image }
                                    })
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
            body: send_message_body({
                                      jid: test_send_jid,
                                      messageContent: { fileName: 'audio.wav', caption: message.content, audio: base64_audio }
                                    })
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
            body: send_message_body({
                                      jid: test_send_jid,
                                      messageContent: { fileName: 'audio.wav', caption: message.content, audio: base64_audio, ptt: true }
                                    })
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
            body: send_message_body({
                                      jid: test_send_jid,
                                      messageContent: { text: message.content }
                                    })
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
            body: send_message_body({
                                      jid: test_send_jid,
                                      messageContent: { text: message.content }
                                    })
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
            body: send_message_body({
                                      jid: test_send_jid,
                                      messageContent: { react: { key: { id: message.source_id,
                                                                        remoteJid: test_send_jid,
                                                                        fromMe: true },
                                                                 text: '👍' } }
                                    }, reaction)
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
            body: send_message_body({
                                      jid: test_send_jid,
                                      messageContent: { react: { key: { id: message.source_id,
                                                                        remoteJid: test_send_jid,
                                                                        fromMe: false },
                                                                 text: '👍' } }
                                    }, reaction)
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
            body: send_message_body({
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
                                    }, reply_message)
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
            body: send_message_body({
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
                                    }, reply_message)
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
            body: send_message_body({
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
                                    }, reply_message)
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
            body: send_message_body({
                                      jid: test_send_jid,
                                      messageContent: { text: 'Regular message' }
                                    }, regular_message)
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
            body: send_message_body({
                                      jid: group_jid,
                                      messageContent: { text: message.content }
                                    })
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

    context 'when reserving the WhatsApp message id' do
      let(:unsent_message) { create(:message, inbox: whatsapp_channel.inbox, content: 'Hello') }

      it 'sends under a reserved id and persists it before the request' do
        stub_request(:post, request_path)
          .to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: result_body.to_json)

        service.send_message(test_send_phone_number, unsent_message)

        reserved = unsent_message.reload.pending_source_id
        expect(reserved).to match(/\A3EB0[0-9A-F]{18}\z/)
        expect(WebMock).to(have_requested(:post, request_path).with { |req| JSON.parse(req.body)['messageId'] == reserved })
        # Stored so the echo handler's lookup can read it back out of the JSON column.
        expect(Message.where("(content_attributes#>>'{}')::jsonb->>'pending_source_id' = ?", reserved)).to exist
      end

      # A send can sit behind the channel lock for minutes; the row may have been re-reserved (or
      # cleared and re-reserved by a reaction toggle) since it was loaded.
      it 'reads the reservation under the lock instead of the copy loaded before waiting' do
        Message.find(unsent_message.id).update!(content_attributes: { pending_source_id: 'RESERVED_ELSEWHERE' })
        stub_request(:post, request_path)
          .to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: result_body.to_json)

        service.send_message(test_send_phone_number, unsent_message)

        expect(WebMock).to(have_requested(:post, request_path).with { |req| JSON.parse(req.body)['messageId'] == 'RESERVED_ELSEWHERE' })
      end

      # The reservation is bookkeeping for a send that has not happened yet: it must not look like a
      # message update to integrations, nor invalidate the idempotency key a retry has to reuse.
      it 'does not touch updated_at when reserving' do
        stub_request(:post, request_path)
          .to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: result_body.to_json)

        expect { service.send_message(test_send_phone_number, unsent_message) }
          .not_to(change { unsent_message.reload.updated_at })
      end

      it 'reuses the reserved id when the same message is sent again' do
        stub_request(:post, request_path)
          .to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: result_body.to_json)

        service.send_message(test_send_phone_number, unsent_message)
        reserved = unsent_message.reload.pending_source_id
        service.send_message(test_send_phone_number, unsent_message)

        expect(unsent_message.reload.pending_source_id).to eq(reserved)
        expect(WebMock).to(have_requested(:post, request_path).with { |req| JSON.parse(req.body)['messageId'] == reserved }.twice)
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

    # Every non-2xx used to collapse into a bare ProviderUnavailableError, so the job
    # retried "this message can never be sent" exactly as hard as "the connection is
    # down", and buried both in the dead set.
    context 'when the server reports the send outcome is unknown' do
      it 'raises a non-retryable error and does not reconnect the channel' do
        stub_request(:post, request_path)
          .to_return(
            status: 409,
            headers: { 'x-baileys-idempotency-state' => 'indeterminate' },
            body: 'Previous send timed out; outcome unknown'
          )

        setup_url = "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}"

        expect do
          service.send_message(test_send_phone_number, message)
        end.to(raise_error do |error|
          expect(error.class.name).to eq('Whatsapp::Providers::WhatsappBaileysService::SendOutcomeUnknownError')
          # Resending could deliver the message twice, and only a human can tell.
          expect(error.retryable?).to be(false)
        end)

        expect(WebMock).not_to have_requested(:post, setup_url)
      end
    end

    context 'when the send times out' do
      it 'raises a retryable timeout error' do
        stub_request(:post, request_path)
          .to_return(status: 504, body: 'Send timed out; outcome unknown')

        expect do
          service.send_message(test_send_phone_number, message)
        end.to(raise_error do |error|
          expect(error.class.name).to eq('Whatsapp::Providers::WhatsappBaileysService::SendTimeoutError')
          expect(error.retryable?).to be(true)
        end)
      end

      # The connection is receiving and answering health checks; only sending is wedged.
      # Marking it closed would drop it out of the health-check cycle that detects
      # exactly this, and POST /connections cannot repair it anyway.
      it 'leaves the channel open so the health check keeps watching it' do
        stub_request(:post, request_path)
          .to_return(status: 504, body: 'Send timed out; outcome unknown')

        setup_url = "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}"

        expect { service.send_message(test_send_phone_number, message) }.to raise_error(StandardError)

        expect(WebMock).not_to have_requested(:post, setup_url)
      end
    end

    # 503 is where the whole episode settles: after the third timeout the API's circuit
    # breaker refuses without touching the socket, so every later send gets this. Folding
    # it into the generic ProviderUnavailableError would mark the channel closed for the
    # entire stall and drop it out of the very cycle meant to detect it.
    context 'when the connection is refusing sends outright' do
      it 'raises a retryable stall error and leaves the channel open' do
        stub_request(:post, request_path)
          .to_return(status: 503, body: 'Connection is not accepting sends',
                     headers: { 'x-baileys-send-state' => 'stalled' })

        setup_url = "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}"

        expect do
          service.send_message(test_send_phone_number, message)
        end.to(raise_error do |error|
          expect(error.class.name).to eq('Whatsapp::Providers::WhatsappBaileysService::SendStalledError')
          # The provider recreates the socket on its own; the next attempt after that works.
          expect(error.retryable?).to be(true)
        end)

        expect(WebMock).not_to have_requested(:post, setup_url)
      end

      # The stall branch is the one that must NOT mark the channel down. An outage and a
      # draining proxy answer the same 503, and applying the stall reading to them leaves
      # a genuinely dead channel recorded as open, skipping the reconnect it needed and
      # dropping it out of the health-check cycle for good.
      it 'treats a 503 without the provider marker as an ordinary outage' do
        stub_request(:post, request_path)
          .to_return(status: 503, body: 'Service Unavailable')
        setup_url = "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}"
        stub_request(:post, setup_url).to_return(status: 200)

        expect do
          service.send_message(test_send_phone_number, message)
        end.to(raise_error do |error|
          expect(error.class.name).to eq('Whatsapp::Providers::WhatsappBaileysService::ProviderUnavailableError')
        end)

        expect(WebMock).to have_requested(:post, setup_url)
      end
    end

    context 'when the attachment is rejected as too large' do
      it 'raises a non-retryable error without marking the channel closed' do
        stub_request(:post, request_path).to_return(status: 413, body: 'Payload Too Large')

        setup_url = "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}"

        expect do
          service.send_message(test_send_phone_number, message)
        end.to raise_error(Whatsapp::Session::Errors::MediaTooLarge)

        # Marking the channel closed here would drop it out of the health-check cycle,
        # which only enqueues channels whose connection is 'open'.
        expect(WebMock).not_to have_requested(:post, setup_url)
      end
    end

    context 'when the message content is rejected' do
      it 'raises a non-retryable error' do
        stub_request(:post, request_path).to_return(status: 422, body: 'Unprocessable')

        setup_url = "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}"

        expect do
          service.send_message(test_send_phone_number, message)
        end.to(raise_error do |error|
          expect(error).to be_a(Whatsapp::Session::Errors::InvalidPayload)
          expect(error.retryable?).to be(false)
        end)

        expect(WebMock).not_to have_requested(:post, setup_url)
      end
    end

    # SendReplyJob persists error.message as external_error when the retries run out, so a
    # bare raise puts the Ruby class name in front of the agent where the reason belongs.
    it 'gives a generic provider failure a reason an agent can read' do
      stub_request(:post, request_path).to_return(status: 500, body: 'Internal Server Error')
      stub_request(:post, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}")
        .to_return(status: 200)

      expect do
        service.send_message(test_send_phone_number, message)
      end.to(raise_error do |error|
        expect(error.message).to eq(I18n.t('errors.inboxes.channel.outgoing.provider_error'))
        expect(error.message).not_to include('WhatsappBaileysService')
      end)
    end

    context 'when the provider is unavailable' do
      it 'raises a retryable provider error' do
        stub_request(:post, request_path)
          .to_return(status: 503, body: 'Service Unavailable')
        stub_request(:post, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}")
          .to_return(status: 200)

        expect do
          service.send_message(test_send_phone_number, message)
        end.to(raise_error do |error|
          expect(error).to be_a(Whatsapp::Session::Errors::ProviderUnavailable)
          expect(error.retryable?).to be(true)
        end)
      end
    end

    context 'when server returns 409 (message already processing)' do
      it 'raises MessageAlreadyProcessingError without triggering channel reconnection' do
        stub_request(:post, request_path)
          .to_return(status: 409, body: 'Message is already being processed')

        setup_url = "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}"

        expect do
          service.send_message(test_send_phone_number, message)
        end.to(raise_error do |error|
          expect(error.class.name).to eq('Whatsapp::Providers::WhatsappBaileysService::MessageAlreadyProcessingError')
        end)

        expect(WebMock).not_to have_requested(:post, setup_url)
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

  describe '#fetch_reachout_timelock' do
    let(:url) { "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}/reachout-timelock" }

    it 'returns the normalized lock when the account is restricted' do
      stub_request(:get, url).to_return(
        status: 200,
        headers: { 'Content-Type' => 'application/json' },
        body: { data: { isActive: true, timeEnforcementEnds: '2026-06-19T21:52:39.000Z', enforcementType: 'RESTRICT_ALL_COMPANIONS' } }.to_json
      )

      expect(service.fetch_reachout_timelock).to eq(
        is_active: true,
        time_enforcement_ends: '2026-06-19T21:52:39.000Z',
        enforcement_type: 'RESTRICT_ALL_COMPANIONS'
      )
    end

    it 'returns is_active false when the account is not restricted' do
      stub_request(:get, url).to_return(
        status: 200,
        headers: { 'Content-Type' => 'application/json' },
        body: { data: { isActive: false, enforcementType: 'DEFAULT' } }.to_json
      )

      expect(service.fetch_reachout_timelock).to eq(is_active: false, enforcement_type: 'DEFAULT')
    end

    it 'returns nil on 404 (number not connected, not "unrestricted")' do
      stub_request(:get, url).to_return(status: 404, body: 'Phone number not connected')

      expect(service.fetch_reachout_timelock).to be_nil
    end

    it 'returns nil on a server error (read-only, never marks the connection closed)' do
      stub_request(:get, url).to_return(status: 500, body: 'Internal Server Error')
      allow(Rails.logger).to receive(:error)

      expect(service.fetch_reachout_timelock).to be_nil
    end
  end

  describe '#fetch_new_chat_cap' do
    let(:url) { "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}/new-chat-cap" }

    it 'returns the raw cap info on success' do
      stub_request(:get, url).to_return(
        status: 200,
        headers: { 'Content-Type' => 'application/json' },
        body: { data: { capping_status: 'CAPPED', total_quota: 100, used_quota: 100, ote_status: 'ELIGIBLE' } }.to_json
      )

      expect(service.fetch_new_chat_cap).to eq(capping_status: 'CAPPED', total_quota: 100, used_quota: 100, ote_status: 'ELIGIBLE')
    end

    it 'returns nil on 404 (number not connected)' do
      stub_request(:get, url).to_return(status: 404, body: 'Phone number not connected')

      expect(service.fetch_new_chat_cap).to be_nil
    end

    it 'returns nil on a server error (read-only, never marks the connection closed)' do
      stub_request(:get, url).to_return(status: 500, body: 'Internal Server Error')
      allow(Rails.logger).to receive(:error)

      expect(service.fetch_new_chat_cap).to be_nil
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

    # A hint for the compose warning: a wedged socket must not hold the web thread for 90 s.
    # A hint gives up first, a lookup inside a web request gives up before the request is cut, and
    # the background recheck waits as long as the provider may take.
    it 'waits as long as the caller can afford' do
      stub_request(:post, request_path).to_return(status: 200, headers: { 'Content-Type' => 'application/json' },
                                                  body: { data: [] }.to_json)
      timeouts = []
      allow(HTTParty).to receive(:post).and_wrap_original do |original, url, **options|
        timeouts << options[:timeout]
        original.call(url, **options)
      end

      service.on_whatsapp(phone_number, deadline: :hint)
      service.on_whatsapp(phone_number, deadline: :request)
      service.on_whatsapp(phone_number)

      # In call order, so an installation whose rack-timeout puts the in-request ceiling at the
      # full one still reads each call as its own.
      expect(timeouts).to eq([10, Whatsapp::BaileysRequestOptions::BAILEYS_IN_REQUEST_OPTIONS[:timeout], 90])
    end

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

        reconnect = stub_request(:post, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}")
                    .to_return(status: 200)
        whatsapp_channel.update_provider_connection!(connection: 'open')

        allow(Rails.logger).to receive(:error)

        expect do
          service.on_whatsapp(phone_number)
        end.to raise_error(Whatsapp::Providers::WhatsappBaileysService::ProviderUnavailableError)

        expect(Rails.logger).to have_received(:error).with('error message')
        # A failed number lookup is "unknown", not a dropped session (fazer-ai/chatwoot#877).
        expect(whatsapp_channel.reload.provider_connection['connection']).to eq('open')
        expect(reconnect).not_to have_been_requested
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
            body: send_message_body({
                                      jid: group_jid,
                                      messageContent: {
                                        text: 'World!',
                                        quotedMessage: {
                                          key: { id: 'incoming_group_msg', remoteJid: group_jid, fromMe: false, participant: participant_lid },
                                          message: { conversation: 'Hello' }
                                        }
                                      }
                                    }, reply_message)
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
            body: send_message_body({
                                      jid: group_jid,
                                      messageContent: {
                                        text: 'World!',
                                        quotedMessage: {
                                          key: { id: 'outgoing_group_msg', remoteJid: group_jid, fromMe: true },
                                          message: { conversation: 'Hello' }
                                        }
                                      }
                                    }, reply_message)
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
            body: send_message_body({
                                      jid: group_jid,
                                      messageContent: {
                                        react: {
                                          key: { id: original_message.source_id, remoteJid: group_jid, fromMe: false, participant: participant_lid },
                                          text: '👍'
                                        }
                                      }
                                    }, reaction)
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
            body: send_message_body({
                                      jid: group_jid,
                                      messageContent: {
                                        react: {
                                          key: { id: original_message.source_id, remoteJid: group_jid, fromMe: true },
                                          text: '❤️'
                                        }
                                      }
                                    }, reaction)
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
              groupsEnabled: described_class.groups_enabled?,
              syncFullHistory: false
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
              groupsEnabled: described_class.groups_enabled?,
              syncFullHistory: false
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
              groupsEnabled: described_class.groups_enabled?,
              syncFullHistory: false
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

  describe 'history sync' do
    let(:history_url) do
      "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}/fetch-message-history"
    end
    let(:contact) { create(:contact, account: whatsapp_channel.inbox.account, phone_number: '+551187654321', identifier: '99887766@lid') }
    let(:conversation) { create(:conversation, inbox: whatsapp_channel.inbox, account: whatsapp_channel.inbox.account, contact: contact) }

    before { create(:contact_inbox, inbox: whatsapp_channel.inbox, contact: contact, source_id: '99887766') }

    describe '#history_sync?' do
      it 'is off until the operator turns it on' do
        expect(service.history_sync?).to be(false)
      end

      it 'is on once the inbox carries the setting' do
        whatsapp_channel.update!(provider_config: whatsapp_channel.provider_config.merge('history_sync' => true))

        expect(service.history_sync?).to be(true)
      end
    end

    describe '#request_history' do
      # WhatsApp can only walk backwards, so a request needs a message to walk back from.
      it 'asks the phone for what came before the oldest stored message' do
        create(:message, conversation: conversation, inbox: whatsapp_channel.inbox, source_id: 'NEWER',
                         created_at: 1.day.ago, content_attributes: { external_created_at: 200 })
        create(:message, conversation: conversation, inbox: whatsapp_channel.inbox, source_id: 'OLDEST',
                         created_at: 5.days.ago, content_attributes: { external_created_at: 100 })
        request = stub_request(:post, history_url)
                  .with(
                    headers: stub_headers(whatsapp_channel),
                    body: {
                      count: 50,
                      oldestMsgKey: { id: 'OLDEST', remoteJid: '99887766@lid', fromMe: false },
                      # In milliseconds: the bridge hands this to `oldestMsgTimestampMs`.
                      oldestMsgTimestamp: 100_000
                    }.to_json
                  )
                  .to_return(status: 200)

        expect(service.request_history(contact)).to be(true)
        expect(request).to have_been_requested
      end

      it 'asks nothing for a contact with no stored message to anchor on' do
        expect(service.request_history(contact)).to be(false)
        expect(a_request(:post, history_url)).not_to have_been_made
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

    # The group contact is read once, at the top of `sync_group`, and every write afterwards
    # merges into that copy. Four network calls happen in between, so anything another writer
    # stores during any of them is in the row and not in the copy, and the next write erases it.
    # No threads: the copy is simply old. One example per window, because each window is a
    # different write, and a fix that only moves the last one leaves the others standing.
    describe 'a writer that lands during one of the network calls' do
      def intrude
        Contact.find(group_contact.id).then do |stored|
          stored.update!(additional_attributes: stored.additional_attributes.merge('custom_note' => 'kept'))
        end
      end

      it 'survives a write during the metadata call, which happens before any write' do
        stub_request(:get, "#{base_url}/group-metadata")
          .with(headers: stub_headers(whatsapp_channel), query: { jid: group_contact.identifier })
          .to_return do
            intrude
            { status: 200, body: metadata.merge(participants: []).to_json }
          end

        service.sync_group(conversation)

        expect(group_contact.reload.additional_attributes).to include('custom_note' => 'kept')
      end

      it 'survives a write during the invite code call' do
        stub_group_metadata(metadata.merge(participants: []))
        stub_request(:get, "#{base_url}/group-invite-code")
          .with(headers: stub_headers(whatsapp_channel), query: { jid: group_contact.identifier })
          .to_return do
            intrude
            # `data.inviteCode` is what the fetcher reads; the shared stub above returns a shape
            # it ignores, so nothing was ever written through this path before.
            { status: 200, body: { data: { inviteCode: 'ABC123' } }.to_json }
          end

        service.sync_group(conversation)

        expect(group_contact.reload.additional_attributes).to include('custom_note' => 'kept', 'invite_code' => 'ABC123')
      end

      it 'survives a write during the join requests call' do
        stub_group_metadata(metadata.merge(participants: []))
        stub_request(:get, "#{base_url}/group-request-participants-list")
          .with(headers: stub_headers(whatsapp_channel), query: { jid: group_contact.identifier })
          .to_return do
            intrude
            { status: 200, body: [].to_json }
          end

        service.sync_group(conversation)

        expect(group_contact.reload.additional_attributes).to include('custom_note' => 'kept')
      end

      # The other half of the same defect: a key the other writer *removed* during the window is
      # still in the old copy, so writing the copy back brings it home from the dead.
      it 'does not resurrect a key removed during the window' do
        group_contact.update!(additional_attributes: { 'custom_note' => 'stale' })
        stub_request(:get, "#{base_url}/group-metadata")
          .with(headers: stub_headers(whatsapp_channel), query: { jid: group_contact.identifier })
          .to_return do
            Contact.find(group_contact.id).update!(additional_attributes: {})
            { status: 200, body: metadata.merge(participants: []).to_json }
          end

        service.sync_group(conversation)

        expect(group_contact.reload.additional_attributes).not_to have_key('custom_note')
      end
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

  # The service reserves the WhatsApp message id before posting, so reserve it here too or the
  # expected body would carry a different `messageId`. The reload matters: the reservation runs
  # under a row lock, which re-reads the row, so the service builds the idempotency key from the
  # database `updated_at` (microseconds) rather than the in-memory one written by `update!`.
  def send_message_body(hash, msg = message)
    msg.update_under_lock!(pending_source_id: 'reserved_msg_id') if msg.pending_source_id.blank?
    msg.reload
    hash.merge(chatwootMessageId: "#{msg.id}:#{msg.updated_at.to_f}", messageId: msg.pending_source_id).to_json
  end
end
