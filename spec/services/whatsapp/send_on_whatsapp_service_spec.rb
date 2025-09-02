require 'rails_helper'

describe Whatsapp::SendOnWhatsappService do
  template_params = {
    name: 'sample_shipping_confirmation',
    namespace: '23423423_2342423_324234234_2343224',
    language: 'en_US',
    category: 'Marketing',
    processed_params: { '1' => '3' }
  }

  describe '#perform' do
    before do
      # Add WebMock stubs for 360Dialog API calls to prevent external requests during tests
      stub_request(:post, 'https://waba.360dialog.io/v1/configs/webhook')
        .to_return(status: 200, body: '', headers: {})
      stub_request(:post, 'https://waba.360dialog.io/v1/messages')
        .to_return(status: 200, body: '{"messages": [{"id": "test_message_id"}]}', headers: { 'Content-Type' => 'application/json' })
      
      # Add missing WebMock stub for 360Dialog templates API call - this was causing the test failures
      stub_request(:get, 'https://waba.360dialog.io/v1/configs/templates')
        .to_return(status: 200, body: '{"waba_templates": []}', headers: { 'Content-Type' => 'application/json' })
        
      # Add WebMock stubs for WhatsApp Cloud API calls
      stub_request(:get, %r{https://graph\.facebook\.com/v\d+\.\d+/.*/message_templates})
        .to_return(status: 200, body: '{"data": []}', headers: { 'Content-Type' => 'application/json' })
      stub_request(:post, %r{https://graph\.facebook\.com/v\d+\.\d+/.*/messages})
        .to_return(status: 200, body: '{"messages": [{"id": "test_cloud_message_id"}]}', headers: { 'Content-Type' => 'application/json' })
    end

    context 'when a valid message' do
      let(:whatsapp_request) { instance_double(HTTParty::Response) }
      let!(:whatsapp_channel) do
        ch = build(:channel_whatsapp, sync_templates: false, validate_provider_config: false,
                   provider_config: { 'api_key' => 'test_key' })
        # Explicitly bypass validation to prevent provider config validation errors
        ch.define_singleton_method(:validate_provider_config) { true }
        ch.define_singleton_method(:sync_templates) { nil }
        
        # Mock the provider_config_object to prevent real API calls during channel operations
        mock_config = double('MockProviderConfig')
        allow(mock_config).to receive(:validate_config?).and_return(true)
        allow(mock_config).to receive(:api_key).and_return('test_key')
        allow(mock_config).to receive(:cleanup_on_destroy)
        allow(ch).to receive(:provider_config_object).and_return(mock_config)
        
        ch.save!(validate: false)
        ch
      end

      let!(:inbox) { create(:inbox, channel: whatsapp_channel) }
      let!(:contact_inbox) { create(:contact_inbox, inbox: inbox, source_id: '123456789') }
      let!(:conversation) { create(:conversation, contact_inbox: contact_inbox, inbox: inbox) }
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
          to: '123456789',
          template: {
            name: 'ticket_status_updated',
            language: { 'policy': 'deterministic', 'code': 'en_US' },
            components: [{ 'type': 'body',
                           'parameters': [{ 'type': 'text', parameter_name: 'last_name', 'text': 'Dale' },
                                          { 'type': 'text', parameter_name: 'ticket_id', 'text': '2332' }] }]
          },
          type: 'template'
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

      it 'calls channel.send_template when after 24 hour limit' do
        message = create(:message, message_type: :outgoing, content: 'Your package has been shipped. It will be delivered in 3 business days.',
                                   conversation: conversation)

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
        # Create WhatsApp Cloud channel with validation bypass
        whatsapp_cloud_channel = build(:channel_whatsapp, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false,
                                        provider_config: { 'api_key' => 'test_cloud_key', 'phone_number_id' => 'test_phone_id', 'business_account_id' => 'test_business_id' })
        whatsapp_cloud_channel.define_singleton_method(:validate_provider_config) { true }
        whatsapp_cloud_channel.define_singleton_method(:sync_templates) { nil }
        whatsapp_cloud_channel.save!(validate: false)
        
        cloud_inbox = create(:inbox, channel: whatsapp_cloud_channel)
        cloud_contact_inbox = create(:contact_inbox, inbox: cloud_inbox, source_id: '123456789')
        cloud_conversation = create(:conversation, contact_inbox: cloud_contact_inbox, inbox: cloud_inbox)

        named_template_params = {
          name: 'ticket_status_updated',
          language: 'en_US',
          category: 'UTILITY',
          processed_params: { 'last_name' => 'Dale', 'ticket_id' => '2332' }
        }

        stub_request(:post, "https://graph.facebook.com/v13.0/test_phone_id/messages")
          .with(
            :headers => { 'Content-Type' => 'application/json', 'Authorization' => "Bearer test_cloud_key" },
            :body => named_template_body.to_json
          ).to_return(status: 200, body: success_response, headers: { 'content-type' => 'application/json' })
        message = create(:message,
                         additional_attributes: { template_params: named_template_params },
                         content: 'Your package will be delivered in 3 business days.', conversation: cloud_conversation, message_type: :outgoing)

        described_class.new(message: message).perform
        expect(message.reload.source_id).to eq('123456789')
      end

      it 'calls channel.send_template when template has regexp characters' do
        message = create(
          :message,
          message_type: :outgoing,
          content: 'عميلنا العزيز الرجاء الرد على هذه الرسالة بكلمة *نعم* للرد على إستفساركم من قبل خدمة العملاء.',
          conversation: conversation
        )

        stub_request(:post, 'https://waba.360dialog.io/v1/messages')
          .with(
            headers: headers,
            body: {
              to: '123456789',
              template: {
                name: 'customer_yes_no',
                namespace: '2342384942_32423423_23423fdsdaf23',
                language: { 'policy': 'deterministic', 'code': 'ar' },
                components: [{ 'type': 'body', 'parameters': [] }]
              },
              type: 'template'
            }.to_json
          ).to_return(status: 200, body: success_response, headers: { 'content-type' => 'application/json' })

        described_class.new(message: message).perform
        expect(message.reload.source_id).to eq('123456789')
      end
    end
  end
end
