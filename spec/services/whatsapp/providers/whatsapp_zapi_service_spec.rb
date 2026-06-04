require 'rails_helper'

describe Whatsapp::Providers::WhatsappZapiService do
  subject(:service) { described_class.new(whatsapp_channel: whatsapp_channel) }

  let(:whatsapp_channel) do
    create(:channel_whatsapp, provider: 'zapi', validate_provider_config: false).tap do |channel|
      channel.provider_config = {
        'instance_id' => 'test_instance',
        'token' => 'test_token',
        'client_token' => 'test_client_token'
      }
      channel.save!
    end
  end
  let(:message) { create(:message, inbox: whatsapp_channel.inbox, source_id: 'msg_123', content_attributes: { external_created_at: 123 }) }

  let(:test_send_phone_number) { '551187654321' }
  let(:api_instance_path) { "#{described_class::API_BASE_PATH}/instances/#{whatsapp_channel.provider_config['instance_id']}" }
  let(:api_instance_path_with_token) { "#{api_instance_path}/token/#{whatsapp_channel.provider_config['token']}" }

  def stub_headers(extra_headers = {})
    {
      'Accept' => '*/*',
      'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
      'Content-Type' => 'application/json',
      'Client-Token' => 'test_client_token',
      'User-Agent' => 'Ruby'
    }.merge(extra_headers)
  end

  describe '#validate_provider_config?' do
    context 'when response is successful' do
      it 'returns true' do
        stub_request(:get, "#{api_instance_path_with_token}/status")
          .with(headers: stub_headers)
          .to_return(status: 200, body: '', headers: {})

        expect(service.validate_provider_config?).to be(true)
      end
    end

    context 'when response is unsuccessful' do
      it 'logs the error and returns false' do
        stub_request(:get, "#{api_instance_path_with_token}/status")
          .with(headers: stub_headers)
          .to_return(status: 400, body: 'error message', headers: {})

        allow(Rails.logger).to receive(:error)

        expect(service.validate_provider_config?).to be(false)
        expect(Rails.logger).to have_received(:error).with('error message')
      end
    end
  end

  describe '#setup_channel_provider' do
    context 'when response is successful' do
      it 'sets up the webhook and returns true' do
        stub_request(:put, "#{api_instance_path_with_token}/update-every-webhooks")
          .with(
            headers: stub_headers,
            body: {
              value: whatsapp_channel.inbox.callback_webhook_url,
              notifySentByMe: true
            }.to_json
          )
          .to_return(status: 200)

        expect(service.setup_channel_provider).to be(true)
      end

      it 'schedules QR code job when connection is blank' do
        whatsapp_channel.update!(provider_connection: {})

        stub_request(:put, "#{api_instance_path_with_token}/update-every-webhooks")
          .with(headers: stub_headers)
          .to_return(status: 200)

        service.setup_channel_provider

        expect(Channels::Whatsapp::ZapiQrCodeJob).to have_been_enqueued.with(whatsapp_channel)
      end

      it 'schedules QR code job when connection is closed' do
        whatsapp_channel.update!(provider_connection: { 'connection' => 'close' })

        stub_request(:put, "#{api_instance_path_with_token}/update-every-webhooks")
          .with(headers: stub_headers)
          .to_return(status: 200)

        service.setup_channel_provider

        expect(Channels::Whatsapp::ZapiQrCodeJob).to have_been_enqueued.with(whatsapp_channel)
      end

      it 'does not schedule QR code job when connection is not closed' do
        whatsapp_channel.update!(provider_connection: { 'connection' => 'open' })

        stub_request(:put, "#{api_instance_path_with_token}/update-every-webhooks")
          .with(headers: stub_headers)
          .to_return(status: 200)

        service.setup_channel_provider

        expect(Channels::Whatsapp::ZapiQrCodeJob).not_to have_been_enqueued
      end
    end

    context 'when response is unsuccessful' do
      it 'raises ProviderUnavailableError' do
        stub_request(:put, "#{api_instance_path_with_token}/update-every-webhooks")
          .with(headers: stub_headers)
          .to_return(status: 400, body: 'error message', headers: {})

        allow(Rails.logger).to receive(:error)

        expect do
          service.setup_channel_provider
        end.to(raise_error { |error| expect(error.class.name).to eq('Whatsapp::Providers::WhatsappZapiService::ProviderUnavailableError') })
      end
    end
  end

  describe '#disconnect_channel_provider' do
    context 'when response is successful' do
      it 'disconnects the whatsapp connection' do
        stub_request(:get, "#{api_instance_path_with_token}/disconnect")
          .with(headers: stub_headers)
          .to_return(status: 200)

        expect(service.disconnect_channel_provider).to be(true)
      end
    end

    context 'when response is unsuccessful' do
      it 'raises ProviderUnavailableError' do
        stub_request(:get, "#{api_instance_path_with_token}/disconnect")
          .with(headers: stub_headers)
          .to_return(status: 400, body: 'error message', headers: {})

        allow(Rails.logger).to receive(:error)

        expect do
          service.disconnect_channel_provider
        end.to(raise_error { |error| expect(error.class.name).to eq('Whatsapp::Providers::WhatsappZapiService::ProviderUnavailableError') })
      end
    end
  end

  describe '#qr_code_image' do
    context 'when response indicates connected' do
      it 'updates provider connection to open and returns nil' do
        stub_request(:get, "#{api_instance_path_with_token}/qr-code/image")
          .with(headers: stub_headers)
          .to_return(status: 200, body: { connected: true }.to_json)

        expect(whatsapp_channel).to receive(:update_provider_connection!).with(connection: 'open')

        result = service.qr_code_image

        expect(result).to be_nil
      end
    end

    context 'when response is successful and not connected' do
      it 'returns the QR code value' do
        qr_code_value = 'base64_qr_code_data'
        response_body = { 'value' => qr_code_value }
        stub_request(:get, "#{api_instance_path_with_token}/qr-code/image")
          .with(headers: stub_headers)
          .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = service.qr_code_image

        expect(result).to eq(qr_code_value)
      end
    end

    context 'when response is unsuccessful' do
      it 'logs error and returns nil' do
        stub_request(:get, "#{api_instance_path_with_token}/qr-code/image")
          .with(headers: stub_headers)
          .to_return(status: 400, body: 'error message', headers: {})

        allow(Rails.logger).to receive(:error)

        result = service.qr_code_image

        expect(result).to be_nil
        expect(Rails.logger).to have_received(:error).with('error message')
      end
    end
  end

  describe '#read_messages' do
    let(:first_message) { create(:message, source_id: 'msg_first') }
    let(:second_message) { create(:message, source_id: 'msg_second') }
    let(:messages) { [first_message, second_message] }

    it 'enqueues a job for each message' do
      service.read_messages(messages, recipient_id: "+#{test_send_phone_number}")

      expect(Channels::Whatsapp::ZapiReadMessageJob).to have_been_enqueued.with(whatsapp_channel, test_send_phone_number, first_message.source_id)
      expect(Channels::Whatsapp::ZapiReadMessageJob).to have_been_enqueued.with(whatsapp_channel, test_send_phone_number, second_message.source_id)
    end

    it 'returns true' do
      result = service.read_messages(messages, recipient_id: "+#{test_send_phone_number}")

      expect(result).to be(true)
    end
  end

  describe '#send_read_message' do
    let(:phone) { test_send_phone_number }
    let(:message_source_id) { 'msg_123' }

    context 'when response is successful' do
      it 'sends a read message request to Z-API' do
        stub_request(:post, "#{api_instance_path_with_token}/read-message")
          .with(
            headers: stub_headers,
            body: { phone: phone, messageId: message_source_id }.to_json
          )
          .to_return(status: 200)

        result = service.send_read_message(phone, message_source_id)

        expect(result).to be(true)
      end
    end

    context 'when response is unsuccessful' do
      it 'logs the error and returns false' do
        stub_request(:post, "#{api_instance_path_with_token}/read-message")
          .with(headers: stub_headers)
          .to_return(status: 400, body: 'error message')

        allow(Rails.logger).to receive(:error)

        result = service.send_read_message(phone, message_source_id)

        expect(result).to be(false)
        expect(Rails.logger).to have_received(:error).with('error message')
      end
    end
  end

  describe '#on_whatsapp' do
    let(:phone_number) { '+123456789' }

    context 'when response is successful' do
      it 'checks if phone number exists on WhatsApp' do
        response_body = { 'exists' => true, 'phone' => '123456789', 'lid' => 'some_lid' }
        stub_request(:get, "#{api_instance_path_with_token}/phone-exists/123456789")
          .with(headers: stub_headers)
          .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = service.on_whatsapp(phone_number)

        expect(result).to eq(response_body)
      end

      it 'returns default response when parsed_response is nil' do
        stub_request(:get, "#{api_instance_path_with_token}/phone-exists/123456789")
          .with(headers: stub_headers)
          .to_return(status: 200, body: '')

        result = service.on_whatsapp(phone_number)

        expect(result).to eq({ 'exists' => false, 'phone' => nil, 'lid' => nil })
      end
    end

    context 'when response is unsuccessful' do
      it 'raises ProviderUnavailableError' do
        stub_request(:get, "#{api_instance_path_with_token}/phone-exists/123456789")
          .with(headers: stub_headers)
          .to_return(status: 400, body: 'error message', headers: {})

        allow(Rails.logger).to receive(:error)

        expect do
          service.on_whatsapp(phone_number)
        end.to(raise_error { |error| expect(error.class.name).to eq('Whatsapp::Providers::WhatsappZapiService::ProviderUnavailableError') })
      end
    end
  end

  describe '#delete_message' do
    let(:outgoing_message) { create(:message, inbox: whatsapp_channel.inbox, source_id: 'msg_456', message_type: :outgoing) }
    let(:incoming_message) { create(:message, inbox: whatsapp_channel.inbox, source_id: 'msg_789', message_type: :incoming) }

    context 'when deleting an outgoing message' do
      it 'sends delete request with owner true' do
        stub_request(:delete, "#{api_instance_path_with_token}/messages")
          .with(
            headers: stub_headers,
            query: { messageId: outgoing_message.source_id, phone: test_send_phone_number, owner: 'true' }
          )
          .to_return(status: 204, body: '{}')

        result = service.delete_message("+#{test_send_phone_number}", outgoing_message)

        expect(result).to be(true)
      end
    end

    context 'when deleting an incoming message' do
      it 'sends delete request with owner false' do
        stub_request(:delete, "#{api_instance_path_with_token}/messages")
          .with(
            headers: stub_headers,
            query: { messageId: incoming_message.source_id, phone: test_send_phone_number, owner: 'false' }
          )
          .to_return(status: 204, body: '{}')

        result = service.delete_message("+#{test_send_phone_number}", incoming_message)

        expect(result).to be(true)
      end
    end

    context 'when response is unsuccessful' do
      it 'raises ProviderUnavailableError and logs the error' do
        stub_request(:delete, "#{api_instance_path_with_token}/messages")
          .with(
            headers: stub_headers,
            query: { messageId: outgoing_message.source_id, phone: test_send_phone_number, owner: 'true' }
          )
          .to_return(status: 400, body: 'error message')

        allow(Rails.logger).to receive(:error)

        expect do
          service.delete_message("+#{test_send_phone_number}", outgoing_message)
        end.to(raise_error { |error| expect(error.class.name).to eq('Whatsapp::Providers::WhatsappZapiService::ProviderUnavailableError') })

        expect(Rails.logger).to have_received(:error).with('error message')
      end
    end
  end

  describe '#send_message' do
    let(:request_path) { "#{api_instance_path_with_token}/send-text" }
    let(:result_body) { { 'messageId' => 'msg_123' } }

    context 'when message is unsupported' do
      it 'updates the message with is_unsupported attribute' do
        unsupported_message = create(:message, content: nil)

        result = service.send_message(test_send_phone_number, unsupported_message)

        expect(unsupported_message.reload.is_unsupported).to be(true)
        expect(result).to be_nil
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
            headers: stub_headers,
            body: {
              phone: test_send_phone_number,
              message: 'Please rate us http://example.com/survey'
            }.to_json
          )
          .to_return(status: 200, body: result_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = service.send_message("+#{test_send_phone_number}", message)

        expect(result).to eq('msg_123')
      end
    end

    context 'when message is a text' do
      it 'sends the text message' do
        stub_request(:post, request_path)
          .with(
            headers: stub_headers,
            body: {
              phone: test_send_phone_number,
              message: message.content
            }.to_json
          )
          .to_return(status: 200, body: result_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = service.send_message("+#{test_send_phone_number}", message)

        expect(result).to eq('msg_123')
      end

      it 'includes zapi_args when present' do
        message.update!(content_attributes: { zapi_args: { delayMessage: 1000 } })

        stub_request(:post, request_path)
          .with(
            headers: stub_headers,
            body: {
              phone: test_send_phone_number,
              message: message.content,
              delayMessage: 1000
            }.to_json
          )
          .to_return(status: 200, body: result_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = service.send_message("+#{test_send_phone_number}", message)

        expect(result).to eq('msg_123')
      end

      context 'when request is unsuccessful' do
        it 'updates message status and raises ProviderUnavailableError' do
          error_response = { 'error' => 'Failed to send message' }
          stub_request(:post, request_path)
            .with(
              headers: stub_headers,
              body: {
                phone: test_send_phone_number,
                message: message.content
              }.to_json
            )
            .to_return(status: 400, body: error_response.to_json, headers: { 'Content-Type' => 'application/json' })

          allow(Rails.logger).to receive(:error)

          expect do
            service.send_message("+#{test_send_phone_number}", message)
          end.to(raise_error { |error| expect(error.class.name).to eq('Whatsapp::Providers::WhatsappZapiService::ProviderUnavailableError') })

          expect(message.reload.status).to eq('failed')
          expect(message.external_error).to eq('Failed to send message')
        end
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

      it 'sends text reply with messageId parameter' do
        original_message = create(:message, inbox: inbox, conversation: conversation, sender: contact,
                                            message_type: 'incoming', source_id: 'original_zapi_msg_123', content: 'Original text')
        reply_message = create(:message, inbox: inbox, conversation: conversation, sender: account_user,
                                         content: 'Reply text', content_attributes: { in_reply_to_external_id: original_message.source_id })

        stub_request(:post, request_path)
          .with(
            headers: stub_headers,
            body: {
              phone: test_send_phone_number,
              message: 'Reply text',
              messageId: 'original_zapi_msg_123'
            }.to_json
          )
          .to_return(status: 200, body: result_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = service.send_message("+#{test_send_phone_number}", reply_message)

        expect(result).to eq('msg_123')
      end

      it 'sends image reply with messageId parameter' do
        base64_image = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII='
        buffer = "data:image/png;base64,#{base64_image}"

        original_message = create(:message, inbox: inbox, conversation: conversation, sender: contact,
                                            message_type: 'incoming', source_id: 'original_zapi_img_456', content: 'Check this')
        reply_message = create(:message, inbox: inbox, conversation: conversation, sender: account_user,
                                         content: 'Nice!', content_attributes: { in_reply_to_external_id: original_message.source_id })
        reply_message.attachments.create!(account_id: reply_message.account_id, file_type: 'image',
                                          file: { io: StringIO.new(Base64.decode64(base64_image)), filename: 'reply.png' })

        stub_request(:post, "#{api_instance_path_with_token}/send-image")
          .with(
            headers: stub_headers,
            body: {
              phone: test_send_phone_number,
              image: buffer,
              caption: 'Nice!',
              messageId: 'original_zapi_img_456'
            }.to_json
          )
          .to_return(status: 200, body: result_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = service.send_message("+#{test_send_phone_number}", reply_message)

        expect(result).to eq('msg_123')
      end

      it 'sends message without messageId when in_reply_to_external_id is blank' do
        regular_message = create(:message, inbox: inbox, conversation: conversation, sender: account_user, content: 'Regular message')

        stub_request(:post, request_path)
          .with(
            headers: stub_headers,
            body: {
              phone: test_send_phone_number,
              message: 'Regular message'
            }.to_json
          )
          .to_return(status: 200, body: result_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = service.send_message("+#{test_send_phone_number}", regular_message)

        expect(result).to eq('msg_123')
      end
    end

    context 'when message is an image file' do
      let(:base64_image) { 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=' }
      let(:buffer) { "data:image/png;base64,#{base64_image}" }

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

      it 'sends the image message' do
        stub_request(:post, "#{api_instance_path_with_token}/send-image")
          .with(
            headers: stub_headers,
            body: {
              phone: test_send_phone_number,
              image: buffer,
              caption: message.content
            }.to_json
          )
          .to_return(status: 200, body: result_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = service.send_message("+#{test_send_phone_number}", message)

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
        stub_request(:post, "#{api_instance_path_with_token}/send-audio")
          .with(
            headers: stub_headers,
            body: hash_including({
                                   phone: test_send_phone_number,
                                   waveform: true
                                 })
          )
          .to_return(status: 200, body: result_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = service.send_message("+#{test_send_phone_number}", message)

        expect(result).to eq('msg_123')
      end
    end

    context 'when message is a video file' do
      let(:base64_video) { 'AAABAAIADAAAAHAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' }

      before do
        message.attachments.create!(
          account_id: message.account_id,
          file_type: 'video',
          file: {
            io: StringIO.new(Base64.decode64(base64_video)),
            filename: 'video.mp4'
          }
        )
      end

      it 'sends the video message' do
        stub_request(:post, "#{api_instance_path_with_token}/send-video")
          .with(
            headers: stub_headers,
            body: hash_including({
                                   phone: test_send_phone_number,
                                   caption: message.content
                                 })
          )
          .to_return(status: 200, body: result_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = service.send_message("+#{test_send_phone_number}", message)

        expect(result).to eq('msg_123')
      end
    end

    context 'when message is a document file' do
      let(:base64_document) { 'JVBERi0xLjQKJcOkw7zDtsOgw7MKMSAwIG9iagp' }

      before do
        message.attachments.create!(
          account_id: message.account_id,
          file_type: 'file',
          file: {
            io: StringIO.new(Base64.decode64(base64_document)),
            filename: 'document.pdf'
          }
        )
      end

      it 'sends the document message' do
        stub_request(:post, "#{api_instance_path_with_token}/send-document/pdf")
          .with(
            headers: stub_headers,
            body: hash_including({
                                   phone: test_send_phone_number,
                                   fileName: 'document.pdf',
                                   caption: message.content
                                 })
          )
          .to_return(status: 200, body: result_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = service.send_message("+#{test_send_phone_number}", message)

        expect(result).to eq('msg_123')
      end

      it 'handles missing file extension gracefully' do
        message.attachments.first.file.blob.update!(filename: 'document')

        stub_request(:post, "#{api_instance_path_with_token}/send-document/bin")
          .with(
            headers: stub_headers,
            body: hash_including({
                                   phone: test_send_phone_number,
                                   fileName: 'document',
                                   caption: message.content
                                 })
          )
          .to_return(status: 200, body: result_body.to_json, headers: { 'Content-Type' => 'application/json' })

        allow(Rails.logger).to receive(:warn)

        result = service.send_message("+#{test_send_phone_number}", message)

        expect(result).to eq('msg_123')
        expect(Rails.logger).to have_received(:warn).with(/Missing file extension/)
      end
    end

    context 'when message is a reply' do
      let(:conversation) { create(:conversation, inbox: whatsapp_channel.inbox) }
      let(:original_message) { create(:message, inbox: whatsapp_channel.inbox, source_id: 'original_msg_123', conversation: conversation) }
      let(:reply_message) do
        create(:message,
               inbox: whatsapp_channel.inbox,
               content: 'This is a reply',
               source_id: 'reply_msg_123',
               conversation: conversation,
               content_attributes: {
                 external_created_at: 123,
                 in_reply_to: original_message.id
               })
      end

      it 'sends the reply message with messageId parameter' do
        stub_request(:post, "#{api_instance_path_with_token}/send-text")
          .with(
            headers: stub_headers,
            body: {
              phone: test_send_phone_number,
              message: reply_message.content,
              messageId: original_message.source_id
            }.to_json
          )
          .to_return(status: 200, body: result_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = service.send_message("+#{test_send_phone_number}", reply_message)

        expect(result).to eq('msg_123')
      end
    end

    context 'when message is a reaction' do
      let(:conversation) { create(:conversation, inbox: whatsapp_channel.inbox) }
      let(:original_message) { create(:message, inbox: whatsapp_channel.inbox, source_id: 'original_msg_456', conversation: conversation) }
      let(:reaction_message) do
        create(:message,
               inbox: whatsapp_channel.inbox,
               content: '👍',
               source_id: 'reaction_msg_789',
               conversation: conversation,
               content_attributes: {
                 is_reaction: true,
                 external_created_at: 123,
                 in_reply_to: original_message.id
               })
      end

      it 'sends the reaction message' do
        stub_request(:post, "#{api_instance_path_with_token}/send-reaction")
          .with(
            headers: stub_headers,
            body: {
              phone: test_send_phone_number,
              reaction: reaction_message.content,
              messageId: original_message.source_id
            }.to_json
          )
          .to_return(status: 200, body: result_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = service.send_message("+#{test_send_phone_number}", reaction_message)

        expect(result).to eq('msg_123')
      end
    end

    context 'when attachment exceeds size limits' do
      it 'rejects image files larger than 5MB' do
        message.attachments.create!(
          account_id: message.account_id,
          file_type: 'image',
          file: {
            io: StringIO.new('fake image content'),
            filename: 'large_image.png'
          }
        )

        attachment = message.attachments.first
        allow(attachment.file).to receive(:byte_size).and_return(6.megabytes)

        result = service.send_message("+#{test_send_phone_number}", message)

        expect(message.reload.status).to eq('failed')
        expect(message.external_error).to eq('File too large')
        expect(result).to be_nil
      end

      it 'rejects audio files larger than 16MB' do
        message.attachments.create!(
          account_id: message.account_id,
          file_type: 'audio',
          file: {
            io: StringIO.new('fake audio content'),
            filename: 'large_audio.mp3'
          }
        )

        attachment = message.attachments.first
        allow(attachment.file).to receive(:byte_size).and_return(17.megabytes)

        result = service.send_message("+#{test_send_phone_number}", message)

        expect(message.reload.status).to eq('failed')
        expect(message.external_error).to eq('File too large')
        expect(result).to be_nil
      end

      it 'rejects video files larger than 16MB' do
        message.attachments.create!(
          account_id: message.account_id,
          file_type: 'video',
          file: {
            io: StringIO.new('fake video content'),
            filename: 'large_video.mp4'
          }
        )

        attachment = message.attachments.first
        allow(attachment.file).to receive(:byte_size).and_return(17.megabytes)

        result = service.send_message("+#{test_send_phone_number}", message)

        expect(message.reload.status).to eq('failed')
        expect(message.external_error).to eq('File too large')
        expect(result).to be_nil
      end

      it 'rejects document files larger than 100MB' do
        message.attachments.create!(
          account_id: message.account_id,
          file_type: 'file',
          file: {
            io: StringIO.new('fake document content'),
            filename: 'large_document.pdf'
          }
        )

        attachment = message.attachments.first
        allow(attachment.file).to receive(:byte_size).and_return(101.megabytes)

        result = service.send_message("+#{test_send_phone_number}", message)

        expect(message.reload.status).to eq('failed')
        expect(message.external_error).to eq('File too large')
        expect(result).to be_nil
      end
    end
  end

  describe '#send_template' do
    it 'is not implemented yet (returns nil)' do
      expect(service.send_template('+123456789', {})).to be_nil
    end
  end

  describe '#sync_templates' do
    it 'is not implemented yet (returns nil)' do
      expect(service.sync_templates).to be_nil
    end
  end
end
