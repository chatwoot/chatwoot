require 'rails_helper'

describe Whatsapp::Providers::WhatsappCloudService do
  subject(:service) { described_class.new(whatsapp_channel: whatsapp_channel) }

  let(:whatsapp_channel) { create(:channel_whatsapp, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false) }
  let(:message) { create(:message, message_type: :outgoing, content: 'test', inbox: whatsapp_channel.inbox) }
  let(:response_headers) { { 'Content-Type' => 'application/json' } }
  let(:whatsapp_response) { { messages: [{ id: 'message_id' }] } }

  before do
    stub_request(:get, 'https://graph.facebook.com/v14.0/123456789/message_templates?access_token=test_key')
  end

  describe '#send_message' do
    context 'when called' do
      it 'calls message endpoints for normal messages' do
        stub_request(:post, 'https://graph.facebook.com/v13.0/123456789/messages')
          .with(
            body: {
              messaging_product: 'whatsapp',
              to: '+123456789',
              text: { body: message.content },
              type: 'text'
            }.to_json
          )
          .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)
        expect(service.send_message('+123456789', message)).to eq 'message_id'
      end

      it 'calls message endpoints for attachment message messages' do
        attachment = message.attachments.new(account_id: message.account_id, file_type: :image)
        attachment.file.attach(io: File.open(Rails.root.join('spec/assets/avatar.png')), filename: 'avatar.png', content_type: 'image/png')

        stub_request(:post, 'https://graph.facebook.com/v13.0/123456789/messages')
          .with(
            body: hash_including({
                                   messaging_product: 'whatsapp',
                                   to: '+123456789',
                                   type: 'image'
                                 })
          )
          .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)
        expect(service.send_message('+123456789', message)).to eq 'message_id'
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

    let(:template_body) do
      {
        messaging_product: 'whatsapp',
        to: '+123456789',
        template: {
          name: template_info[:name],
          language: {
            policy: 'deterministic',
            code: template_info[:lang_code]
          },
          components: [
            { type: 'body',
              parameters: template_info[:parameters] }
          ]
        },
        type: 'template'
      }
    end

    context 'when called' do
      it 'calls message endpoints with template params for template messages' do
        stub_request(:post, 'https://graph.facebook.com/v13.0/123456789/messages')
          .with(
            body: template_body.to_json
          )
          .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)

        expect(service.send_template('+123456789', template_info)).to eq('message_id')
      end
    end
  end

  describe '#sync_templates' do
    context 'when called' do
      it 'updated the message templates' do
        stub_request(:get, 'https://graph.facebook.com/v14.0/123456789/message_templates?access_token=test_key')
          .to_return(status: 200, headers: response_headers, body: { data: [{ id: '123456789', name: 'test_template' }] }.to_json)
        expect(subject.sync_templates).to be(true)
        expect(whatsapp_channel.reload.message_templates).to eq([{ id: '123456789', name: 'test_template' }.stringify_keys])
      end
    end
  end

  describe '#validate_provider_config' do
    context 'when called' do
      it 'returns true if valid' do
        stub_request(:get, 'https://graph.facebook.com/v14.0/123456789/message_templates?access_token=test_key')
        expect(subject.validate_provider_config?).to be(true)
        expect(whatsapp_channel.errors.present?).to be(false)
      end

      it 'returns false if invalid' do
        stub_request(:get, 'https://graph.facebook.com/v14.0/123456789/message_templates?access_token=test_key').to_return(status: 401)
        expect(subject.validate_provider_config?).to be(false)
      end
    end
  end
end
