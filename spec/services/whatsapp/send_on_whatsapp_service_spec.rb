require 'rails_helper'

describe Whatsapp::SendOnWhatsappService do
  template_params = {
    name: 'sample_shipping_confirmation',
    namespace: '23423423_2342423_324234234_2343224',
    language: 'en_US',
    category: 'Marketing',
    processed_params: { 'body' => { '1' => '3' } }
  }

  describe '#perform' do
    before do
      stub_request(:post, 'https://waba.360dialog.io/v1/configs/webhook')
      stub_request(:post, 'https://waba.360dialog.io/v1/messages')
    end

    context 'when a valid message' do
      let(:whatsapp_request) { instance_double(HTTParty::Response) }
      let!(:whatsapp_channel) { create(:channel_whatsapp, sync_templates: false) }

      let!(:contact_inbox) { create(:contact_inbox, inbox: whatsapp_channel.inbox, source_id: '123456789') }
      let!(:conversation) { create(:conversation, contact_inbox: contact_inbox, inbox: whatsapp_channel.inbox) }
      let(:api_key) { 'test_key' }
      let(:headers) { { 'D360-API-KEY' => api_key, 'Content-Type' => 'application/json' } }
      let(:template_body) do
        {
          to: '123456789',
          template: {
            name: 'sample_shipping_confirmation',
            namespace: '23423423_2342423_324234234_2343224',
            language: { 'policy': 'deterministic', 'code': 'en_US' },
            components: [{ 'type': 'body', 'parameters': [{ 'type': 'text', 'text': '3' }] }]
          },
          type: 'template'
        }
      end

      let(:named_template_body) do
        {
          messaging_product: 'whatsapp',
          recipient_type: 'individual',
          to: '123456789',
          type: 'template',
          template: {
            name: 'ticket_status_updated',
            language: { 'policy': 'deterministic', 'code': 'en_US' },
            components: [{ 'type': 'body',
                           'parameters': [{ 'type': 'text', parameter_name: 'last_name', 'text': 'Dale' },
                                          { 'type': 'text', parameter_name: 'ticket_id', 'text': '2332' }] }]
          }
        }
      end

      let(:success_response) { { 'messages' => [{ 'id' => '123456789' }] }.to_json }

      it 'calls channel.send_message when with in 24 hour limit' do
        # to handle the case of 24 hour window limit.
        create(:message, message_type: :incoming, content: 'test',
                         conversation: conversation)
        message = create(:message, message_type: :outgoing, content: 'test',
                                   conversation: conversation)

        stub_request(:post, 'https://waba.360dialog.io/v1/messages')
          .with(
            headers: headers,
            body: { 'to' => '123456789', 'text' => { 'body' => 'test' }, 'type' => 'text' }.to_json
          )
          .to_return(status: 200, body: success_response, headers: { 'content-type' => 'application/json' })

        described_class.new(message: message).perform
        expect(message.reload.source_id).to eq('123456789')
      end

      it 'marks message as failed when template name is blank' do
        processor = instance_double(Whatsapp::TemplateProcessorService)
        allow(Whatsapp::TemplateProcessorService).to receive(:new).and_return(processor)
        allow(processor).to receive(:call).and_return([nil, nil, nil, nil])

        invalid_template_params = {
          name: '',
          namespace: 'test_namespace',
          language: 'en_US',
          category: 'UTILITY',
          processed_params: { '1' => 'test' }
        }

        message = create(:message,
                         additional_attributes: { template_params: invalid_template_params },
                         conversation: conversation,
                         message_type: :outgoing)

        described_class.new(message: message).perform

        expect(message.reload.status).to eq('failed')
        expect(message.reload.external_error).to eq('Template not found or invalid template name')
      end

      it 'calls channel.send_template when after 24 hour limit' do
        message = create(:message, message_type: :outgoing, content: 'Your package has been shipped. It will be delivered in 3 business days.',
                                   conversation: conversation, additional_attributes: { template_params: template_params })

        stub_request(:post, 'https://waba.360dialog.io/v1/messages')
          .with(
            headers: headers,
            body: template_body.to_json
          ).to_return(status: 200, body: success_response, headers: { 'content-type' => 'application/json' })

        described_class.new(message: message).perform
        expect(message.reload.source_id).to eq('123456789')
      end

      it 'calls channel.send_template if template_params are present' do
        message = create(:message, additional_attributes: { template_params: template_params },
                                   content: 'Your package will be delivered in 3 business days.', conversation: conversation, message_type: :outgoing)
        stub_request(:post, 'https://waba.360dialog.io/v1/messages')
          .with(
            headers: headers,
            body: template_body.to_json
          ).to_return(status: 200, body: success_response, headers: { 'content-type' => 'application/json' })

        described_class.new(message: message).perform
        expect(message.reload.source_id).to eq('123456789')
      end

      it 'calls channel.send_template with named params if template parameter type is NAMED' do
        whatsapp_cloud_channel = create(:channel_whatsapp, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false)
        cloud_contact_inbox = create(:contact_inbox, inbox: whatsapp_cloud_channel.inbox, source_id: '123456789')
        cloud_conversation = create(:conversation, contact_inbox: cloud_contact_inbox, inbox: whatsapp_cloud_channel.inbox)

        named_template_params = {
          name: 'ticket_status_updated',
          language: 'en_US',
          category: 'UTILITY',
          processed_params: { 'body' => { 'last_name' => 'Dale', 'ticket_id' => '2332' } }
        }

        stub_request(:post, "https://graph.facebook.com/v13.0/#{whatsapp_cloud_channel.provider_config['phone_number_id']}/messages")
          .with(
            :headers => {
              'Accept' => '*/*',
              'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
              'Content-Type' => 'application/json',
              'Authorization' => "Bearer #{whatsapp_cloud_channel.provider_config['api_key']}",
              'User-Agent' => 'Ruby'
            },
            :body => named_template_body.to_json
          ).to_return(status: 200, body: success_response, headers: { 'content-type' => 'application/json' })
        message = create(:message,
                         additional_attributes: { template_params: named_template_params },
                         content: 'Your package will be delivered in 3 business days.', conversation: cloud_conversation, message_type: :outgoing)

        described_class.new(message: message).perform
        expect(message.reload.source_id).to eq('123456789')
      end

      it 'calls channel.send_template when template has regexp characters' do
        regexp_template_params = build_template_params('customer_yes_no', '2342384942_32423423_23423fdsdaf23', 'ar', {})
        arabic_content = 'عميلنا العزيز الرجاء الرد على هذه الرسالة بكلمة *نعم* للرد على إستفساركم من قبل خدمة العملاء.'
        message = create_message_with_template(arabic_content, regexp_template_params)
        stub_template_request(regexp_template_params, [])

        described_class.new(message: message).perform
        expect(message.reload.source_id).to eq('123456789')
      end

      it 'handles template with header parameters' do
        processed_params = {
          'body' => { '1' => '3' },
          'header' => { 'media_url' => 'https://example.com/image.jpg', 'media_type' => 'image' }
        }
        header_template_params = build_sample_template_params(processed_params)
        message = create_message_with_template('', header_template_params)

        components = [
          { type: 'header', parameters: [{ type: 'image', image: { link: 'https://example.com/image.jpg' } }] },
          { type: 'body', parameters: [{ type: 'text', text: '3' }] }
        ]
        stub_sample_template_request(components)

        described_class.new(message: message).perform
        expect(message.reload.source_id).to eq('123456789')
      end

      it 'handles empty processed_params gracefully' do
        empty_template_params = {
          name: 'sample_shipping_confirmation',
          namespace: '23423423_2342423_324234234_2343224',
          language: 'en_US',
          category: 'SHIPPING_UPDATE',
          processed_params: {}
        }

        message = create(:message, additional_attributes: { template_params: empty_template_params },
                                   conversation: conversation, message_type: :outgoing)

        stub_request(:post, 'https://waba.360dialog.io/v1/messages')
          .with(
            headers: headers,
            body: {
              to: '123456789',
              template: {
                name: 'sample_shipping_confirmation',
                namespace: '23423423_2342423_324234234_2343224',
                language: { 'policy': 'deterministic', 'code': 'en_US' },
                components: []
              },
              type: 'template'
            }.to_json
          ).to_return(status: 200, body: success_response, headers: { 'content-type' => 'application/json' })

        described_class.new(message: message).perform
        expect(message.reload.source_id).to eq('123456789')
      end

      it 'handles template with button parameters' do
        processed_params = {
          'body' => { '1' => '3' },
          'buttons' => [{ 'type' => 'url', 'parameter' => 'https://track.example.com/123' }]
        }
        button_template_params = build_sample_template_params(processed_params)
        message = create_message_with_template('', button_template_params)

        components = [
          { type: 'body', parameters: [{ type: 'text', text: '3' }] },
          { type: 'button', sub_type: 'url', index: 0, parameters: [{ type: 'text', text: 'https://track.example.com/123' }] }
        ]
        stub_sample_template_request(components)

        described_class.new(message: message).perform
        expect(message.reload.source_id).to eq('123456789')
      end

      it 'processes template parameters correctly via integration' do
        processed_params = {
          'body' => { '1' => '5' },
          'footer' => { 'text' => 'Thank you' }
        }
        complex_template_params = build_sample_template_params(processed_params)
        message = create_message_with_template('', complex_template_params)

        components = [
          { type: 'body', parameters: [{ type: 'text', text: '5' }] },
          { type: 'footer', parameters: [{ type: 'text', text: 'Thank you' }] }
        ]
        stub_sample_template_request(components)

        expect { described_class.new(message: message).perform }.not_to raise_error
        expect(message.reload.source_id).to eq('123456789')
      end

      it 'handles edge case with missing template gracefully' do
        # Test the service behavior when template is not found
        missing_template_params = {
          'name' => 'non_existent_template',
          'namespace' => 'missing_namespace',
          'language' => 'en_US',
          'category' => 'UTILITY',
          'processed_params' => { 'body' => { '1' => 'test' } }
        }

        service = Whatsapp::TemplateProcessorService.new(
          channel: whatsapp_channel,
          template_params: missing_template_params
        )

        expect { service.call }.not_to raise_error
        name, namespace, language, processed_params = service.call
        expect(name).to eq('non_existent_template')
        expect(namespace).to eq('missing_namespace')
        expect(language).to eq('en_US')
        expect(processed_params).to be_nil
      end

      it 'handles template with blank parameter values correctly' do
        processed_params = {
          'body' => { '1' => '', '2' => 'valid_value', '3' => nil },
          'header' => { 'media_url' => '', 'media_type' => 'image' }
        }
        blank_values_template_params = build_sample_template_params(processed_params)
        message = create_message_with_template('', blank_values_template_params)

        components = [{ type: 'body', parameters: [{ type: 'text', text: 'valid_value' }] }]
        stub_sample_template_request(components)

        described_class.new(message: message).perform
        expect(message.reload.source_id).to eq('123456789')
      end

      it 'handles nil template_params gracefully' do
        # Test service behavior when template_params is completely nil
        message = create(:message, additional_attributes: {},
                                   conversation: conversation, message_type: :outgoing)

        # Should send regular message, not template
        stub_request(:post, 'https://waba.360dialog.io/v1/messages')
          .with(
            headers: headers,
            body: {
              to: '123456789',
              text: { body: message.content },
              type: 'text'
            }.to_json
          ).to_return(status: 200, body: success_response, headers: { 'content-type' => 'application/json' })

        expect { described_class.new(message: message).perform }.not_to raise_error
      end

      it 'processes template with rich text formatting' do
        processed_params = { 'body' => { '1' => '*Bold text* and _italic text_' } }
        rich_text_template_params = build_sample_template_params(processed_params)
        message = create_message_with_template('', rich_text_template_params)

        components = [{ type: 'body', parameters: [{ type: 'text', text: '*Bold text* and _italic text_' }] }]
        stub_sample_template_request(components)

        described_class.new(message: message).perform
        expect(message.reload.source_id).to eq('123456789')
      end

      private

      def build_template_params(name, namespace, language, processed_params)
        {
          name: name,
          namespace: namespace,
          language: language,
          category: 'SHIPPING_UPDATE',
          processed_params: processed_params
        }
      end

      def create_message_with_template(content, template_params)
        create(:message,
               message_type: :outgoing,
               content: content,
               conversation: conversation,
               additional_attributes: { template_params: template_params })
      end

      def stub_template_request(template_params, components)
        stub_request(:post, 'https://waba.360dialog.io/v1/messages')
          .with(
            headers: headers,
            body: {
              to: '123456789',
              template: {
                name: template_params[:name],
                namespace: template_params[:namespace],
                language: { 'policy': 'deterministic', 'code': template_params[:language] },
                components: components
              },
              type: 'template'
            }.to_json
          ).to_return(status: 200, body: success_response, headers: { 'content-type' => 'application/json' })
      end

      def build_sample_template_params(processed_params)
        build_template_params('sample_shipping_confirmation', '23423423_2342423_324234234_2343224', 'en_US', processed_params)
      end

      def stub_sample_template_request(components)
        stub_request(:post, 'https://waba.360dialog.io/v1/messages')
          .with(
            headers: headers,
            body: {
              to: '123456789',
              template: {
                name: 'sample_shipping_confirmation',
                namespace: '23423423_2342423_324234234_2343224',
                language: { 'policy': 'deterministic', 'code': 'en_US' },
                components: components
              },
              type: 'template'
            }.to_json
          ).to_return(status: 200, body: success_response, headers: { 'content-type' => 'application/json' })
      end
    end
  end
end
