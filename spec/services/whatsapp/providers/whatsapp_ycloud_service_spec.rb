require 'rails_helper'

describe Whatsapp::Providers::WhatsappYcloudService do
  subject(:service) { described_class.new(whatsapp_channel: whatsapp_channel) }

  let(:whatsapp_channel) { create(:channel_whatsapp, provider: 'ycloud', sync_templates: false, validate_provider_config: false) }
  let(:conversation) { create(:conversation, inbox: whatsapp_channel.inbox) }

  let(:message) do
    create(:message, conversation: conversation, message_type: :outgoing, content: 'test', inbox: whatsapp_channel.inbox, source_id: 'external_id')
  end

  let(:message_with_reply) do
    create(:message, conversation: conversation, message_type: :outgoing, content: 'reply', inbox: whatsapp_channel.inbox,
                     content_attributes: { in_reply_to: message.id })
  end

  let(:response_headers) { { 'Content-Type' => 'application/json' } }
  let(:ycloud_response) { { id: 'ycloud_msg_id', wamid: 'wamid.xxx' } }
  let(:ycloud_api_base) { 'https://api.ycloud.com/v2' }

  describe '#send_message' do
    context 'when sending a text message' do
      it 'calls sendDirectly endpoint with correct payload' do
        stub_request(:post, "#{ycloud_api_base}/whatsapp/messages/sendDirectly")
          .with(
            body: {
              from: whatsapp_channel.phone_number,
              to: '+123456789',
              type: 'text',
              text: { body: message.content }
            }.to_json
          )
          .to_return(status: 200, body: ycloud_response.to_json, headers: response_headers)

        expect(service.send_message('+123456789', message)).to eq 'ycloud_msg_id'
      end

      it 'includes reply context when replying to a message' do
        stub_request(:post, "#{ycloud_api_base}/whatsapp/messages/sendDirectly")
          .with(
            body: {
              from: whatsapp_channel.phone_number,
              to: '+123456789',
              type: 'text',
              text: { body: message_with_reply.content },
              context: { message_id: message.source_id }
            }.to_json
          )
          .to_return(status: 200, body: ycloud_response.to_json, headers: response_headers)

        expect(service.send_message('+123456789', message_with_reply)).to eq 'ycloud_msg_id'
      end
    end

    context 'when sending an image attachment' do
      it 'sends image with caption' do
        attachment = message.attachments.new(account_id: message.account_id, file_type: :image)
        attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')

        stub_request(:post, "#{ycloud_api_base}/whatsapp/messages/sendDirectly")
          .with(
            body: hash_including({
                                   'from' => whatsapp_channel.phone_number,
                                   'to' => '+123456789',
                                   'type' => 'image',
                                   'image' => WebMock::API.hash_including({ 'caption' => message.content, 'link' => anything })
                                 })
          )
          .to_return(status: 200, body: ycloud_response.to_json, headers: response_headers)

        expect(service.send_message('+123456789', message)).to eq 'ycloud_msg_id'
      end
    end

    context 'when sending a document attachment' do
      it 'sends document with filename and caption' do
        attachment = message.attachments.new(account_id: message.account_id, file_type: :file)
        attachment.file.attach(io: Rails.root.join('spec/assets/sample.pdf').open, filename: 'sample.pdf', content_type: 'application/pdf')

        stub_request(:post, "#{ycloud_api_base}/whatsapp/messages/sendDirectly")
          .with(
            body: hash_including({
                                   'from' => whatsapp_channel.phone_number,
                                   'to' => '+123456789',
                                   'type' => 'document',
                                   'document' => WebMock::API.hash_including({ 'filename' => 'sample.pdf', 'caption' => message.content,
                                                                               'link' => anything })
                                 })
          )
          .to_return(status: 200, body: ycloud_response.to_json, headers: response_headers)

        expect(service.send_message('+123456789', message)).to eq 'ycloud_msg_id'
      end
    end
  end

  describe '#send_interactive message' do
    context 'when items count is 3 or fewer' do
      it 'sends a button payload' do
        interactive_message = create(:message, message_type: :outgoing, content: 'Pick one',
                                               inbox: whatsapp_channel.inbox, content_type: 'input_select',
                                               content_attributes: {
                                                 items: [
                                                   { title: 'Option A', value: 'a' },
                                                   { title: 'Option B', value: 'b' },
                                                   { title: 'Option C', value: 'c' }
                                                 ]
                                               })

        stub_request(:post, "#{ycloud_api_base}/whatsapp/messages/sendDirectly")
          .with(
            body: {
              from: whatsapp_channel.phone_number,
              to: '+123456789',
              type: 'interactive',
              interactive: {
                type: 'button',
                body: { text: 'Pick one' },
                action: '{"buttons":[{"type":"reply","reply":{"id":"a","title":"Option A"}},' \
                        '{"type":"reply","reply":{"id":"b","title":"Option B"}},' \
                        '{"type":"reply","reply":{"id":"c","title":"Option C"}}]}'
              }
            }.to_json
          )
          .to_return(status: 200, body: ycloud_response.to_json, headers: response_headers)

        expect(service.send_message('+123456789', interactive_message)).to eq 'ycloud_msg_id'
      end
    end

    context 'when items count is greater than 3' do
      it 'sends a list payload' do
        interactive_message = create(:message, message_type: :outgoing, content: 'Pick one',
                                               inbox: whatsapp_channel.inbox, content_type: 'input_select',
                                               content_attributes: {
                                                 items: [
                                                   { title: 'A', value: 'a' },
                                                   { title: 'B', value: 'b' },
                                                   { title: 'C', value: 'c' },
                                                   { title: 'D', value: 'd' }
                                                 ]
                                               })

        stub_request(:post, "#{ycloud_api_base}/whatsapp/messages/sendDirectly")
          .with(
            body: {
              from: whatsapp_channel.phone_number,
              to: '+123456789',
              type: 'interactive',
              interactive: {
                type: 'list',
                body: { text: 'Pick one' },
                action: '{"button":"Choose an item","sections":[{"rows":[{"id":"a","title":"A"},' \
                        '{"id":"b","title":"B"},{"id":"c","title":"C"},{"id":"d","title":"D"}]}]}'
              }
            }.to_json
          )
          .to_return(status: 200, body: ycloud_response.to_json, headers: response_headers)

        expect(service.send_message('+123456789', interactive_message)).to eq 'ycloud_msg_id'
      end
    end
  end

  describe '#send_template' do
    let(:template_info) do
      {
        name: 'test_template',
        namespace: 'test_namespace',
        lang_code: 'en_US',
        parameters: [{ type: 'text', text: 'test' }]
      }
    end

    it 'sends template via sendDirectly endpoint' do
      stub_request(:post, "#{ycloud_api_base}/whatsapp/messages/sendDirectly")
        .with(
          body: {
            from: whatsapp_channel.phone_number,
            to: '+123456789',
            type: 'template',
            template: {
              name: 'test_template',
              language: { policy: 'deterministic', code: 'en_US' },
              components: [{ type: 'body', parameters: [{ type: 'text', text: 'test' }] }]
            }
          }.to_json
        )
        .to_return(status: 200, body: ycloud_response.to_json, headers: response_headers)

      expect(service.send_template('+123456789', template_info)).to eq 'ycloud_msg_id'
    end
  end

  describe '#sync_templates' do
    it 'fetches and normalizes templates with pagination' do
      page1_response = {
        items: [
          { name: 'template_1', status: 'APPROVED', language: 'en', category: 'MARKETING', wabaId: 'waba_123',
            components: [{ type: 'BODY', text: 'Hello {{1}}' }] }
        ],
        total: 2
      }
      page2_response = {
        items: [
          { name: 'template_2', status: 'PENDING', language: 'es', category: 'UTILITY', wabaId: 'waba_123',
            components: [{ type: 'BODY', text: 'Hola {{1}}' }] }
        ],
        total: 2
      }

      stub_request(:get, "#{ycloud_api_base}/whatsapp/templates?page=1&limit=100")
        .to_return(status: 200, body: page1_response.to_json, headers: response_headers)
      stub_request(:get, "#{ycloud_api_base}/whatsapp/templates?page=2&limit=100")
        .to_return(status: 200, body: page2_response.to_json, headers: response_headers)

      service.sync_templates

      templates = whatsapp_channel.reload.message_templates
      expect(templates.length).to eq(2)
      expect(templates.first).to include('name' => 'template_1', 'status' => 'approved', 'namespace' => 'waba_123', 'category' => 'MARKETING')
      expect(templates.second).to include('name' => 'template_2', 'status' => 'pending', 'namespace' => 'waba_123', 'category' => 'UTILITY')
    end

    it 'updates message_templates_last_updated even when fetch fails' do
      stub_request(:get, "#{ycloud_api_base}/whatsapp/templates?page=1&limit=100")
        .to_return(status: 401)

      timestamp = whatsapp_channel.reload.message_templates_last_updated
      service.sync_templates
      expect(whatsapp_channel.reload.message_templates_last_updated).not_to eq(timestamp)
    end
  end

  describe '#validate_provider_config?' do
    it 'returns true and registers webhook when API key is valid' do
      stub_request(:get, "#{ycloud_api_base}/whatsapp/templates?limit=1")
        .to_return(status: 200, body: { items: [] }.to_json, headers: response_headers)
      webhook_stub = stub_request(:post, "#{ycloud_api_base}/webhookEndpoints")
        .to_return(status: 200, body: { id: 'wh_123' }.to_json, headers: response_headers)

      expect(service.validate_provider_config?).to be true
      expect(webhook_stub).to have_been_requested
    end

    it 'returns false when API key is invalid' do
      stub_request(:get, "#{ycloud_api_base}/whatsapp/templates?limit=1")
        .to_return(status: 401)

      expect(service.validate_provider_config?).to be false
    end

    it 'still returns true even if webhook registration fails' do
      stub_request(:get, "#{ycloud_api_base}/whatsapp/templates?limit=1")
        .to_return(status: 200, body: { items: [] }.to_json, headers: response_headers)
      stub_request(:post, "#{ycloud_api_base}/webhookEndpoints")
        .to_raise(StandardError.new('connection refused'))

      expect(service.validate_provider_config?).to be true
    end
  end

  describe '#handle_error' do
    let(:error_response) { { 'errorMessage' => 'Invalid phone number', 'errorCode' => 'E1001' } }
    let(:error_response_object) do
      instance_double(HTTParty::Response, body: error_response.to_json, parsed_response: error_response, success?: false)
    end

    before { allow(Rails.logger).to receive(:error) }

    it 'marks message as failed with error details' do
      service.instance_variable_set(:@message, message)
      service.send(:handle_error, error_response_object)

      expect(message.reload.status).to eq('failed')
      expect(message.reload.external_error).to eq('Invalid phone number')
    end

    context 'when error uses "message" field instead of "errorMessage"' do
      let(:error_response) { { 'message' => 'Rate limit exceeded' } }

      it 'falls back to message field' do
        service.instance_variable_set(:@message, message)
        service.send(:handle_error, error_response_object)

        expect(message.reload.status).to eq('failed')
        expect(message.reload.external_error).to eq('Rate limit exceeded')
      end
    end
  end

  describe 'base URL configuration' do
    it 'uses default YCloud API base URL' do
      expect(service.send(:api_base_path)).to eq('https://api.ycloud.com/v2')
    end

    it 'uses custom base URL from environment variable' do
      with_modified_env YCLOUD_BASE_URL: 'https://sandbox.ycloud.com/v2' do
        expect(service.send(:api_base_path)).to eq('https://sandbox.ycloud.com/v2')
      end
    end
  end

  describe '#api_headers' do
    it 'includes X-API-Key and Content-Type headers' do
      headers = service.api_headers
      expect(headers['X-API-Key']).to eq('test_key')
      expect(headers['Content-Type']).to eq('application/json')
    end
  end

  describe '#media_url' do
    it 'returns the correct media download URL' do
      expect(service.media_url('media_123')).to eq("#{ycloud_api_base}/whatsapp/media/download/media_123")
    end
  end
end
