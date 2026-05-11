require 'rails_helper'

describe Whatsapp::TemplateSyncService do
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

  let(:template_data_approved) do
    {
      'id' => 'template_123',
      'name' => 'hello_world',
      'status' => 'APPROVED',
      'category' => 'MARKETING',
      'language' => 'en_US',
      'parameter_format' => 'POSITIONAL',
      'components' => [
        { 'type' => 'BODY', 'text' => 'Hello !' }
      ],
      'sub_category' => 'CUSTOM'
    }
  end

  let(:template_data_pending) do
    {
      'id' => 'template_456',
      'name' => 'welcome_message',
      'status' => 'PENDING',
      'category' => 'UTILITY',
      'language' => 'es',
      'parameter_format' => 'NAMED',
      'components' => [
        { 'type' => 'HEADER', 'format' => 'TEXT', 'text' => 'Welcome!' },
        { 'type' => 'BODY', 'text' => 'Thank you for joining us!' }
      ]
    }
  end

  let(:template_data_rejected) do
    {
      'id' => 'template_789',
      'name' => 'promotional_offer',
      'status' => 'REJECTED',
      'category' => 'AUTHENTICATION',
      'language' => 'fr_CA',
      'components' => [
        { 'type' => 'BODY', 'text' => 'Your verification code is ' }
      ]
    }
  end

  let(:templates) { [template_data_approved, template_data_pending, template_data_rejected] }

  describe '#call' do
    context 'when sync succeeds' do
      before do
        allow(Rails.logger).to receive(:error)
      end

      it 'returns true and syncs all templates' do
        service = described_class.new(channel: whatsapp_channel, templates: templates)
        result = service.call

        expect(result).to be true
        expect(MessageTemplate.count).to eq(3)
      end

      it 'does not trigger provider sync callbacks during import' do
        provider_double = instance_double(Whatsapp::Providers::WhatsappCloudService)
        allow(Whatsapp::Providers::WhatsappCloudService).to receive(:new).and_return(provider_double)
        expect(provider_double).not_to receive(:sync_templates)

        service = described_class.new(channel: whatsapp_channel, templates: [template_data_approved])
        service.call
      end

      it 'creates new templates with correct attributes' do
        freeze_time do
          service = described_class.new(channel: whatsapp_channel, templates: templates)
          service.call

          approved_template = MessageTemplate.find_by(platform_template_id: 'template_123')
          expect(approved_template).to have_attributes(
            name: 'hello_world',
            status: 'approved',
            category: 'marketing',
            language: 'en',
            channel_type: 'Channel::Whatsapp',
            parameter_format: 'positional',
            content: { 'components' => [{ 'type' => 'BODY', 'text' => 'Hello !' }] },
            metadata: { 'whatsapp_sub_category' => 'CUSTOM' },
            account: account,
            inbox: inbox,
            last_synced_at: Time.current
          )
        end
      end

      it 'updates existing templates' do
        existing_template = create(:message_template,
                                   platform_template_id: 'template_123',
                                   account: account,
                                   inbox: inbox,
                                   name: 'old_name',
                                   status: 'pending')

        service = described_class.new(channel: whatsapp_channel, templates: templates)
        service.call

        existing_template.reload
        expect(existing_template.name).to eq('hello_world')
        expect(existing_template.status).to eq('approved')
        expect(existing_template.category).to eq('marketing')
      end

      it 'handles different statuses correctly' do
        service = described_class.new(channel: whatsapp_channel, templates: templates)
        service.call

        approved = MessageTemplate.find_by(platform_template_id: 'template_123')
        pending = MessageTemplate.find_by(platform_template_id: 'template_456')
        rejected = MessageTemplate.find_by(platform_template_id: 'template_789')

        expect(approved.status).to eq('approved')
        expect(pending.status).to eq('pending')
        expect(rejected.status).to eq('rejected')
      end

      it 'normalizes language codes correctly' do
        service = described_class.new(channel: whatsapp_channel, templates: templates)
        service.call

        en_template = MessageTemplate.find_by(platform_template_id: 'template_123')
        es_template = MessageTemplate.find_by(platform_template_id: 'template_456')
        fr_template = MessageTemplate.find_by(platform_template_id: 'template_789')

        expect(en_template.language).to eq('en')  # en_US -> en
        expect(es_template.language).to eq('es')  # es -> es
        expect(fr_template.language).to eq('fr')  # fr_CA -> fr
      end

      it 'handles parameter formats correctly' do
        service = described_class.new(channel: whatsapp_channel, templates: templates)
        service.call

        positional = MessageTemplate.find_by(platform_template_id: 'template_123')
        named = MessageTemplate.find_by(platform_template_id: 'template_456')
        nil_format = MessageTemplate.find_by(platform_template_id: 'template_789')

        expect(positional.parameter_format).to eq('positional')
        expect(named.parameter_format).to eq('named')
        expect(nil_format.parameter_format).to be_nil
      end

      it 'extracts metadata correctly' do
        service = described_class.new(channel: whatsapp_channel, templates: templates)
        service.call

        with_metadata = MessageTemplate.find_by(platform_template_id: 'template_123')
        without_metadata = MessageTemplate.find_by(platform_template_id: 'template_456')

        expect(with_metadata.metadata).to eq({ 'whatsapp_sub_category' => 'CUSTOM' })
        expect(without_metadata.metadata).to eq({})
      end

      it 'sets last_synced_at timestamp' do
        freeze_time do
          service = described_class.new(channel: whatsapp_channel, templates: templates)
          service.call

          template = MessageTemplate.first
          expect(template.last_synced_at).to be_within(1.second).of(Time.current)
        end
      end
    end

    context 'when individual template sync fails' do
      let(:invalid_template_data) do
        {
          'id' => 'invalid_template',
          'name' => '',  # Invalid: empty name
          'status' => 'APPROVED',
          'category' => 'MARKETING',
          'language' => 'en'
        }
      end

      before do
        allow(Rails.logger).to receive(:error)
      end

      it 'logs error and continues with other templates' do
        mixed_templates = [template_data_approved, invalid_template_data, template_data_pending]
        service = described_class.new(channel: whatsapp_channel, templates: mixed_templates)

        result = service.call

        expect(result).to be true
        expect(Rails.logger).to have_received(:error).with(/Failed to sync template invalid_template/)
        expect(MessageTemplate.count).to eq(2)  # Only valid templates created
      end
    end

    context 'when sync fails with exception' do
      it 'returns false and logs error' do
        allow(Rails.logger).to receive(:error)
        service = described_class.new(channel: whatsapp_channel, templates: templates)
        allow(service).to receive(:sync_templates_to_database)
          .and_raise(StandardError, 'Database connection failed')

        result = service.call

        expect(result).to be false
        expect(Rails.logger).to have_received(:error)
          .with('WhatsApp template sync failed: Database connection failed')
      end
    end

    context 'with empty templates array' do
      it 'returns true without creating templates' do
        service = described_class.new(channel: whatsapp_channel, templates: [])
        result = service.call

        expect(result).to be true
        expect(MessageTemplate.count).to eq(0)
      end
    end
  end

  describe 'private methods' do
    let(:service) { described_class.new(channel: whatsapp_channel, templates: templates) }
    let(:template) { build(:message_template, account: account, inbox: inbox) }

    describe '#update_template_attributes' do
      it 'assigns all template attributes correctly' do
        freeze_time do
          service.send(:update_template_attributes, template, template_data_approved)

          expect(template).to have_attributes(
            name: 'hello_world',
            status: 'approved',
            category: 'marketing',
            language: 'en',
            channel_type: 'Channel::Whatsapp',
            parameter_format: 'positional',
            content: { 'components' => [{ 'type' => 'BODY', 'text' => 'Hello !' }] },
            metadata: { 'whatsapp_sub_category' => 'CUSTOM' },
            last_synced_at: Time.current
          )
        end
      end

      it 'uses formatter service for enum conversions' do
        allow(Whatsapp::TemplateFormatterService).to receive(:format_status_from_meta).and_call_original
        allow(Whatsapp::TemplateFormatterService).to receive(:format_category_from_meta).and_call_original
        allow(Whatsapp::TemplateFormatterService).to receive(:format_parameter_format_from_meta).and_call_original

        service.send(:update_template_attributes, template, template_data_approved)

        expect(Whatsapp::TemplateFormatterService).to have_received(:format_status_from_meta).with('APPROVED')
        expect(Whatsapp::TemplateFormatterService).to have_received(:format_category_from_meta).with('MARKETING')
        expect(Whatsapp::TemplateFormatterService).to have_received(:format_parameter_format_from_meta).with('POSITIONAL')
      end
    end

    describe '#sync_individual_template' do
      before do
        allow(service).to receive(:find_or_initialize_template).and_return(template)
        allow(service).to receive(:update_template_attributes)
        allow(Rails.logger).to receive(:error)
      end

      it 'resets skip_provider_sync flag after successful save' do
        allow(template).to receive(:save!).and_return(true)

        service.send(:sync_individual_template, template_data_approved)

        expect(template.skip_provider_sync).to be(false)
      end

      it 'resets skip_provider_sync flag even when save raises error' do
        allow(template).to receive(:save!).and_raise(StandardError, 'boom')

        service.send(:sync_individual_template, template_data_approved)

        expect(template.skip_provider_sync).to be(false)
      end
    end
  end
end
