require 'rails_helper'

describe Whatsapp::Providers::WhatsappBaileysService do
  subject(:service) { described_class.new(whatsapp_channel: whatsapp_channel) }

  let(:whatsapp_channel) { create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false) }
  let(:message) { create(:message) }

  let(:test_send_phone_number) { '+5511987654321' }

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
              webhookVerifyToken: whatsapp_channel.provider_config['webhook_verify_token']
            }.to_json
          )
          .to_return(status: 200)

        response = service.setup_channel_provider

        expect(response).to be true
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
              webhookVerifyToken: whatsapp_channel.provider_config['webhook_verify_token']
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

        expect(response).to be true
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
    context 'when message has attachment' do
      let(:base64_image) { 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=' }

      before do
        message.attachments.new(
          account_id: message.account_id,
          file_type: 'image',
          file: {
            io: StringIO.new(Base64.decode64(base64_image)),
            filename: 'image.png'
          }
        )
        message.save!
      end

      it 'sends the attachment message' do
        stub_request(:post, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}/send-message")
          .with(
            headers: stub_headers(whatsapp_channel),
            body: {
              recipient: test_send_phone_number,
              messageContent: { fileName: 'image.png', caption: message.content, image: base64_image }
            }.to_json
          )
          .to_return(
            status: 200,
            headers: { 'Content-Type' => 'application/json' },
            body: { 'data' => { 'key' => { 'id' => 'msg_123' } } }.to_json
          )

        result = service.send_message(test_send_phone_number, message)

        expect(result).to eq('msg_123')
      end

      context 'when request is unsuccessful' do
        it 'raises MessageNotSentError' do
          stub_request(:post, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}/send-message")
            .to_return(
              status: 400,
              headers: { 'Content-Type' => 'application/json' },
              body: { 'data' => { 'key' => { 'id' => 'msg_123' } } }.to_json
            )

          expect do
            service.send_message(test_send_phone_number, message)
          end.to raise_error(Whatsapp::Providers::WhatsappBaileysService::MessageNotSentError)
        end
      end
    end

    context 'when message does not have content nor attachments' do
      it 'updates the message status to failed' do
        message.update!(content: nil)

        service.send_message(test_send_phone_number, message)

        expect(message.status).to eq('failed')
      end
    end

    context 'when message is a text' do
      it 'sends the message' do
        stub_request(:post, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}/send-message")
          .to_return(
            status: 200,
            headers: { 'Content-Type' => 'application/json' },
            body: { 'data' => { 'key' => { 'id' => 'msg_123' } } }.to_json
          )

        result = service.send_message(test_send_phone_number, message)

        expect(result).to eq('msg_123')
      end

      it 'raises MessageNotSentError' do
        stub_request(:post, "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}/send-message")
          .to_return(
            status: 400,
            headers: { 'Content-Type' => 'application/json' },
            body: { 'data' => { 'key' => { 'id' => 'msg_123' } } }.to_json
          )

        expect do
          service.send_message(test_send_phone_number, message)
        end.to raise_error(Whatsapp::Providers::WhatsappBaileysService::MessageNotSentError)
      end
    end

    context "when message doesn't have attachment and content" do
      it 'does not send the message' do
        message.update!(content: nil)

        service.send_message(test_send_phone_number, message)

        expect(message.status).to eq('failed')
        expect(message.content).to eq(I18n.t('errors.messages.send.unsupported'))
      end
    end
  end

  describe '#api_headers' do
    context 'when called' do
      it 'returns the headers' do
        expect(service.api_headers).to eq('x-api-key' => 'test_key', 'Content-Type' => 'application/json')
      end
    end
  end

  describe '#validate_provider_config?' do
    context 'when response is successful' do
      it 'returns true' do
        stub_request(:get, "#{whatsapp_channel.provider_config['provider_url']}/status/auth")
          .with(headers: stub_headers(whatsapp_channel))
          .to_return(status: 200, body: '', headers: {})

        expect(service.validate_provider_config?).to be true
      end
    end

    context 'when response is unsuccessful' do
      it 'logs the error and returns false' do
        stub_request(:get, "#{whatsapp_channel.provider_config['provider_url']}/status/auth")
          .with(headers: stub_headers(whatsapp_channel))
          .to_return(status: 400, body: 'error message', headers: {})
        allow(Rails.logger).to receive(:error).with('error message')

        expect(service.validate_provider_config?).to be false
        expect(Rails.logger).to have_received(:error)
      end

      context 'when provider responds with 5XX' do
        it 'updated provider connection to close' do
          whatsapp_channel.update!(provider_connection: { 'connection' => 'open' })
          allow(HTTParty).to receive(:post).with(
            "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}/send-message",
            headers: stub_headers(whatsapp_channel),
            body: {
              recipient: test_send_phone_number,
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
