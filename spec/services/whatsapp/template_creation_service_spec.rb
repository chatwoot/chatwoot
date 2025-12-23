require 'rails_helper'

describe Whatsapp::TemplateCreationService do
  let(:account) { create(:account) }
  let(:whatsapp_channel) do
    create(:channel_whatsapp,
           account: account,
           provider: 'whatsapp_cloud',
           sync_templates: false,
           validate_provider_config: false,
           phone_number: '+1234567890')
  end
  let(:inbox) { whatsapp_channel.inbox }

  describe '#call' do
    context 'when template creation succeeds' do
      it 'creates template successfully and updates platform_template_id' do
        message_template = build(:message_template,
                                 account: account,
                                 inbox: inbox,
                                 name: 'test_template',
                                 platform_template_id: nil,
                                 content: { 'components' => [{ 'type' => 'BODY', 'text' => 'Hello!' }] })

        provider_service = instance_double(Whatsapp::Providers::WhatsappCloudService)
        allow(whatsapp_channel).to receive(:provider_service).and_return(provider_service)
        allow(provider_service).to receive(:create_message_template).and_return({ 'id' => 'template_123', 'status' => 'PENDING' })

        service = described_class.new(message_template: message_template)
        result = service.call

        expect(result).to be true
        expect(message_template.platform_template_id).to eq('template_123')
        expect(message_template.status).to eq('pending')
      end

      context 'with media uploads' do
        let(:content_with_media) do
          {
            'components' => [
              { 'type' => 'HEADER', 'format' => 'IMAGE', 'media' => { 'blobId' => 'blob123' } },
              { 'type' => 'BODY', 'text' => 'Hello!' }
            ]
          }
        end

        it 'processes media uploads when header component has media' do
          message_template = build(:message_template,
                                   account: account,
                                   inbox: inbox,
                                   name: 'test_template_media',
                                   platform_template_id: nil,
                                   content: content_with_media)

          provider_service = instance_double(Whatsapp::Providers::WhatsappCloudService)
          facebook_client = instance_double(Whatsapp::FacebookApiClient)

          allow(whatsapp_channel).to receive(:provider_service).and_return(provider_service)
          allow(Whatsapp::FacebookApiClient).to receive(:new).and_return(facebook_client)
          allow(facebook_client).to receive(:upload_media_for_template)
            .with(blob_id: 'blob123', format: 'IMAGE')
            .and_return({ handle: 'media_handle_123' })
          allow(provider_service).to receive(:create_message_template).and_return({ 'id' => 'template_456', 'status' => 'PENDING' })

          service = described_class.new(message_template: message_template)
          result = service.call

          expect(result).to be true
          header_component = message_template.content['components'].find { |c| c['type'] == 'HEADER' }
          expect(header_component['example']['header_handle']).to eq(['media_handle_123'])
          expect(header_component['media']).to be_nil
        end
      end
    end

    context 'when template creation fails' do
      it 'returns false and logs error' do
        message_template = build(:message_template,
                                 account: account,
                                 inbox: inbox,
                                 name: 'test_template_fail',
                                 platform_template_id: nil,
                                 content: { 'components' => [{ 'type' => 'BODY', 'text' => 'Hello!' }] })

        provider_service = instance_double(Whatsapp::Providers::WhatsappCloudService)
        allow(whatsapp_channel).to receive(:provider_service).and_return(provider_service)
        allow(provider_service).to receive(:create_message_template).and_raise(StandardError, 'API Error')

        logger_double = instance_double(ActiveSupport::BroadcastLogger)
        allow(Rails).to receive(:logger).and_return(logger_double)
        allow(logger_double).to receive(:error)

        service = described_class.new(message_template: message_template)
        result = service.call

        expect(result).to be false
        expect(logger_double).to have_received(:error).with('WhatsApp template creation failed: API Error')
        expect(message_template.errors[:base]).to include('Failed to create template: API Error')
      end

      it 'returns false when media upload fails' do
        content_with_media = {
          'components' => [
            { 'type' => 'HEADER', 'format' => 'IMAGE', 'media' => { 'blobId' => 'blob123' } },
            { 'type' => 'BODY', 'text' => 'Hello!' }
          ]
        }
        message_template = build(:message_template,
                                 account: account,
                                 inbox: inbox,
                                 name: 'test_template_media_fail',
                                 platform_template_id: nil,
                                 content: content_with_media)

        facebook_client = instance_double(Whatsapp::FacebookApiClient)
        allow(Whatsapp::FacebookApiClient).to receive(:new).and_return(facebook_client)
        allow(facebook_client).to receive(:upload_media_for_template)
          .and_return({ error: 'Upload failed' })

        logger_double = instance_double(ActiveSupport::BroadcastLogger)
        allow(Rails).to receive(:logger).and_return(logger_double)
        allow(logger_double).to receive(:error)

        service = described_class.new(message_template: message_template)
        result = service.call

        expect(result).to be false
        expect(logger_double).to have_received(:error)
      end
    end

    context 'when validation fails' do
      it 'returns false when template is not for WhatsApp channel' do
        message_template = build(:message_template,
                                 account: account,
                                 inbox: inbox,
                                 name: 'test_template_invalid_channel',
                                 platform_template_id: nil,
                                 channel_type: 'Channel::Email',
                                 content: { 'components' => [{ 'type' => 'BODY', 'text' => 'Hello!' }] })

        service = described_class.new(message_template: message_template)
        result = service.call

        expect(result).to be false
      end

      it 'returns false when template already has platform_template_id' do
        message_template = build(:message_template,
                                 account: account,
                                 inbox: inbox,
                                 name: 'test_template_existing_id',
                                 platform_template_id: 'existing_id',
                                 content: { 'components' => [{ 'type' => 'BODY', 'text' => 'Hello!' }] })

        service = described_class.new(message_template: message_template)
        result = service.call

        expect(result).to be false
      end

      it 'returns false when content has no components' do
        message_template = build(:message_template,
                                 account: account,
                                 inbox: inbox,
                                 name: 'test_template_no_components',
                                 platform_template_id: nil,
                                 content: {})

        service = described_class.new(message_template: message_template)
        result = service.call

        expect(result).to be false
        expect(message_template.errors[:content]).to include('Components are required')
      end

      it 'returns false when content has no BODY component' do
        message_template = build(:message_template,
                                 account: account,
                                 inbox: inbox,
                                 name: 'test_template_no_body',
                                 platform_template_id: nil,
                                 content: { 'components' => [{ 'type' => 'HEADER', 'text' => 'Header only' }] })

        service = described_class.new(message_template: message_template)
        result = service.call

        expect(result).to be false
        expect(message_template.errors[:content]).to include('Must have exactly one BODY component')
      end

      it 'returns false when content has multiple BODY components' do
        message_template = build(:message_template,
                                 account: account,
                                 inbox: inbox,
                                 name: 'test_template_multiple_body',
                                 platform_template_id: nil,
                                 content: {
                                   'components' => [
                                     { 'type' => 'BODY', 'text' => 'First body' },
                                     { 'type' => 'BODY', 'text' => 'Second body' }
                                   ]
                                 })

        service = described_class.new(message_template: message_template)
        result = service.call

        expect(result).to be false
        expect(message_template.errors[:content]).to include('Must have exactly one BODY component')
      end
    end
  end

  describe 'private methods' do
    let(:message_template) do
      build(:message_template,
            account: account,
            inbox: inbox,
            name: 'test_template_params',
            platform_template_id: nil,
            category: 'marketing',
            language: 'en',
            parameter_format: 'positional',
            content: { 'components' => [{ 'type' => 'BODY', 'text' => 'Hello!' }] })
    end

    describe '#template_params' do
      it 'returns correctly formatted parameters for WhatsApp API' do
        allow(Whatsapp::TemplateFormatterService).to receive(:format_category_for_meta)
          .with('marketing').and_return('MARKETING')
        allow(Whatsapp::TemplateFormatterService).to receive(:format_parameter_format_for_meta)
          .with('positional').and_return('STANDARD')

        service = described_class.new(message_template: message_template)
        params = service.send(:template_params)

        expect(params).to eq({
                               name: 'test_template_params',
                               language: 'en',
                               category: 'MARKETING',
                               components: [{ 'type' => 'BODY', 'text' => 'Hello!' }],
                               parameter_format: 'STANDARD'
                             })
      end
    end

    describe '#update_component_with_handle' do
      it 'updates header component with media handle and removes media key' do
        content_with_media = {
          'components' => [
            { 'type' => 'HEADER', 'format' => 'IMAGE', 'media' => { 'blobId' => 'blob123' } },
            { 'type' => 'BODY', 'text' => 'Hello!' }
          ]
        }
        message_template.content = content_with_media

        service = described_class.new(message_template: message_template)
        service.send(:update_component_with_handle, 'media_handle_456')

        header_component = message_template.content['components'].find { |c| c['type'] == 'HEADER' }
        expect(header_component['example']['header_handle']).to eq(['media_handle_456'])
        expect(header_component.key?('media')).to be false
      end
    end
  end
end
