require 'rails_helper'

describe Whatsapp::Providers::WhatsappCloudService do
  subject(:service) { described_class.new(whatsapp_channel: whatsapp_channel) }

  let(:conversation) { create(:conversation, inbox: whatsapp_channel.inbox) }
  let(:whatsapp_channel) { create(:channel_whatsapp, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false) }

  let(:message) do
    create(:message, conversation: conversation, message_type: :outgoing, content: 'test', inbox: whatsapp_channel.inbox, source_id: 'external_id')
  end

  let(:message_with_reply) do
    create(:message, conversation: conversation, message_type: :outgoing, content: 'reply', inbox: whatsapp_channel.inbox,
                     content_attributes: { in_reply_to: message.id })
  end

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
              context: nil,
              to: '+123456789',
              text: { body: message.content },
              type: 'text'
            }.to_json
          )
          .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)
        expect(service.send_message('+123456789', message)).to eq 'message_id'
      end

      it 'calls message endpoints for a reply to messages' do
        stub_request(:post, 'https://graph.facebook.com/v13.0/123456789/messages')
          .with(
            body: {
              messaging_product: 'whatsapp',
              context: {
                message_id: message.source_id
              },
              to: '+123456789',
              text: { body: message_with_reply.content },
              type: 'text'
            }.to_json
          )
          .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)
        expect(service.send_message('+123456789', message_with_reply)).to eq 'message_id'
      end

      it 'calls message endpoints for image attachment message messages' do
        attachment = message.attachments.new(account_id: message.account_id, file_type: :image)
        attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')

        stub_request(:post, 'https://graph.facebook.com/v13.0/123456789/messages')
          .with(
            body: hash_including({
                                   messaging_product: 'whatsapp',
                                   to: '+123456789',
                                   type: 'image',
                                   image: WebMock::API.hash_including({ caption: message.content, link: anything })
                                 })
          )
          .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)
        expect(service.send_message('+123456789', message)).to eq 'message_id'
      end

      it 'calls message endpoints for document attachment message messages' do
        attachment = message.attachments.new(account_id: message.account_id, file_type: :file)
        attachment.file.attach(io: Rails.root.join('spec/assets/sample.pdf').open, filename: 'sample.pdf', content_type: 'application/pdf')

        # ref: https://github.com/bblimke/webmock/issues/900
        # reason for Webmock::API.hash_including
        stub_request(:post, 'https://graph.facebook.com/v13.0/123456789/messages')
          .with(
            body: hash_including({
                                   messaging_product: 'whatsapp',
                                   to: '+123456789',
                                   type: 'document',
                                   document: WebMock::API.hash_including({ filename: 'sample.pdf', caption: message.content, link: anything })
                                 })
          )
          .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)
        expect(service.send_message('+123456789', message)).to eq 'message_id'
      end
    end
  end

  describe '#send_interactive message' do
    context 'when called' do
      it 'calls message endpoints with button payload when number of items is less than or equal to 3' do
        message = create(:message, message_type: :outgoing, content: 'test',
                                   inbox: whatsapp_channel.inbox, content_type: 'input_select',
                                   content_attributes: {
                                     items: [
                                       { title: 'Burito', value: 'Burito' },
                                       { title: 'Pasta', value: 'Pasta' },
                                       { title: 'Sushi', value: 'Sushi' }
                                     ]
                                   })
        stub_request(:post, 'https://graph.facebook.com/v13.0/123456789/messages')
          .with(
            body: {
              messaging_product: 'whatsapp', to: '+123456789',
              interactive: {
                type: 'button',
                body: {
                  text: 'test'
                },
                action: '{"buttons":[{"type":"reply","reply":{"id":"Burito","title":"Burito"}},{"type":"reply",' \
                        '"reply":{"id":"Pasta","title":"Pasta"}},{"type":"reply","reply":{"id":"Sushi","title":"Sushi"}}]}'
              }, type: 'interactive'
            }.to_json
          ).to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)
        expect(service.send_message('+123456789', message)).to eq 'message_id'
      end

      it 'calls message endpoints with list payload when number of items is greater than 3' do
        message = create(:message, message_type: :outgoing, content: 'test', inbox: whatsapp_channel.inbox,
                                   content_type: 'input_select',
                                   content_attributes: {
                                     items: [
                                       { title: 'Burito', value: 'Burito' },
                                       { title: 'Pasta', value: 'Pasta' },
                                       { title: 'Sushi', value: 'Sushi' },
                                       { title: 'Salad', value: 'Salad' }
                                     ]
                                   })
        stub_request(:post, 'https://graph.facebook.com/v13.0/123456789/messages')
          .with(
            body: {
              messaging_product: 'whatsapp', to: '+123456789',
              interactive: {
                type: 'list',
                body: {
                  text: 'test'
                },
                action: '{"button":"Choose an item","sections":[{"rows":[{"id":"Burito","title":"Burito"},' \
                        '{"id":"Pasta","title":"Pasta"},{"id":"Sushi","title":"Sushi"},{"id":"Salad","title":"Salad"}]}]}'
              }, type: 'interactive'
            }.to_json
          ).to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)
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
          .to_return(
            { status: 200, headers: response_headers,
              body: { data: [
                { id: '123456789', name: 'test_template' }
              ], paging: { next: 'https://graph.facebook.com/v14.0/123456789/message_templates?access_token=test_key' } }.to_json },
            { status: 200, headers: response_headers,
              body: { data: [
                { id: '123456789', name: 'next_template' }
              ], paging: { next: 'https://graph.facebook.com/v14.0/123456789/message_templates?access_token=test_key' } }.to_json },
            { status: 200, headers: response_headers,
              body: { data: [
                { id: '123456789', name: 'last_template' }
              ], paging: { prev: 'https://graph.facebook.com/v14.0/123456789/message_templates?access_token=test_key' } }.to_json }
          )

        timstamp = whatsapp_channel.reload.message_templates_last_updated
        expect(subject.sync_templates).to be(true)
        expect(whatsapp_channel.reload.message_templates.first).to eq({ id: '123456789', name: 'test_template' }.stringify_keys)
        expect(whatsapp_channel.reload.message_templates.second).to eq({ id: '123456789', name: 'next_template' }.stringify_keys)
        expect(whatsapp_channel.reload.message_templates.last).to eq({ id: '123456789', name: 'last_template' }.stringify_keys)
        expect(whatsapp_channel.reload.message_templates_last_updated).not_to eq(timstamp)
      end

      it 'updates message_templates_last_updated even when template request fails' do
        stub_request(:get, 'https://graph.facebook.com/v14.0/123456789/message_templates?access_token=test_key')
          .to_return(status: 401)

        timstamp = whatsapp_channel.reload.message_templates_last_updated
        subject.sync_templates
        expect(whatsapp_channel.reload.message_templates_last_updated).not_to eq(timstamp)
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

  describe 'Ability to configure Base URL' do
    context 'when environment variable WHATSAPP_CLOUD_BASE_URL is not set' do
      it 'uses the default base url' do
        expect(subject.send(:api_base_path)).to eq('https://graph.facebook.com')
      end
    end

    context 'when environment variable WHATSAPP_CLOUD_BASE_URL is set' do
      it 'uses the base url from the environment variable' do
        with_modified_env WHATSAPP_CLOUD_BASE_URL: 'http://test.com' do
          expect(subject.send(:api_base_path)).to eq('http://test.com')
        end
      end
    end
  end

  describe '#handle_error' do
    let(:error_message) { 'Invalid message format' }
    let(:error_response) do
      {
        'error' => {
          'message' => error_message,
          'code' => 100
        }
      }
    end

    let(:error_response_object) do
      instance_double(
        HTTParty::Response,
        body: error_response.to_json,
        parsed_response: error_response
      )
    end

    before do
      allow(Rails.logger).to receive(:error)
    end

    context 'when there is a message' do
      it 'logs error and updates message status' do
        service.instance_variable_set(:@message, message)
        service.send(:handle_error, error_response_object)

        expect(message.reload.status).to eq('failed')
        expect(message.reload.external_error).to eq(error_message)
      end
    end

    context 'when error message is blank' do
      let(:error_response_object) do
        instance_double(
          HTTParty::Response,
          body: '{}',
          parsed_response: {}
        )
      end

      it 'logs error but does not update message' do
        service.instance_variable_set(:@message, message)
        service.send(:handle_error, error_response_object)

        expect(message.reload.status).not_to eq('failed')
        expect(message.reload.external_error).to be_nil
      end
    end
  end
end
