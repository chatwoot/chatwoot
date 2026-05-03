require 'rails_helper'

RSpec.describe Whatsapp::JusmonitoriaAlertTemplateService do
  let(:account) { create(:account) }

  describe '#status' do
    it 'marks whatsapp_cloud delivery as unlocked only when the fixed template is approved' do
      channel = create(
        :channel_whatsapp,
        account: account,
        provider: 'whatsapp_cloud',
        sync_templates: false,
        validate_provider_config: false,
        message_templates: [
          {
            'id' => 'template_123',
            'name' => 'alerta_movimentacao_processual_v1',
            'language' => 'pt_BR',
            'category' => 'UTILITY',
            'parameter_format' => 'NAMED',
            'status' => 'APPROVED'
          }
        ]
      )

      result = described_class.new(channel.inbox).status

      expect(result).to include(
        provider: 'whatsapp_cloud',
        template_required: true,
        template_name: 'alerta_movimentacao_processual_v1',
        category: 'UTILITY',
        requested_category: 'UTILITY',
        template_category: 'UTILITY',
        template_parameter_format: 'NAMED',
        language: 'pt_BR',
        template_status: 'approved',
        delivery_locked: false,
        template_id: 'template_123'
      )
    end

    it 'does not require templates for evolution_go inboxes' do
      provision_service = instance_double(EvolutionGo::ProvisionService, perform: true)
      allow(EvolutionGo::ProvisionService).to receive(:new).and_return(provision_service)

      channel = create(
        :channel_whatsapp,
        account: account,
        provider: 'evolution_go',
        sync_templates: false,
        validate_provider_config: false
      )

      result = described_class.new(channel.inbox).status

      expect(result).to include(
        provider: 'evolution_go',
        template_required: false,
        template_status: 'not_required',
        delivery_locked: false
      )
    end

    it 'reports the category returned by Meta separately from the requested Utility category' do
      channel = create(
        :channel_whatsapp,
        account: account,
        provider: 'whatsapp_cloud',
        sync_templates: false,
        validate_provider_config: false,
        message_templates: [
          {
            'id' => 'template_789',
            'name' => 'alerta_movimentacao_processual_v1',
            'language' => 'pt_BR',
            'category' => 'MARKETING',
            'parameter_format' => 'NAMED',
            'status' => 'APPROVED'
          }
        ]
      )

      result = described_class.new(channel.inbox).status

      expect(result).to include(
        category: 'UTILITY',
        requested_category: 'UTILITY',
        template_category: 'MARKETING',
        template_parameter_format: 'NAMED',
        template_status: 'approved',
        delivery_locked: false
      )
    end

    it 'selects a requested canonical version and exposes all JusMonitorIA versions' do
      channel = create(
        :channel_whatsapp,
        account: account,
        provider: 'whatsapp_cloud',
        sync_templates: false,
        validate_provider_config: false,
        message_templates: [
          {
            'id' => 'template_v1',
            'name' => 'alerta_movimentacao_processual_v1',
            'language' => 'pt_BR',
            'category' => 'UTILITY',
            'parameter_format' => 'NAMED',
            'status' => 'APPROVED'
          },
          {
            'id' => 'template_v2',
            'name' => 'alerta_movimentacao_processual_v2',
            'language' => 'pt_BR',
            'category' => 'UTILITY',
            'parameter_format' => 'NAMED',
            'status' => 'PENDING'
          }
        ]
      )

      result = described_class.new(
        channel.inbox,
        template_name: 'alerta_movimentacao_processual_v2'
      ).status

      expect(result).to include(
        template_name: 'alerta_movimentacao_processual_v2',
        template_status: 'pending',
        template_id: 'template_v2',
        delivery_locked: true
      )
      expect(result[:available_templates]).to include(
        hash_including(name: 'alerta_movimentacao_processual_v1', version: 1, status: 'approved'),
        hash_including(name: 'alerta_movimentacao_processual_v2', version: 2, status: 'pending')
      )
    end

    it 'exposes missing v2 as an explicit image-header template option' do
      channel = create(
        :channel_whatsapp,
        account: account,
        provider: 'whatsapp_cloud',
        sync_templates: false,
        validate_provider_config: false,
        message_templates: [
          {
            'id' => 'template_v1',
            'name' => 'alerta_movimentacao_processual_v1',
            'language' => 'pt_BR',
            'category' => 'UTILITY',
            'parameter_format' => 'NAMED',
            'status' => 'APPROVED'
          }
        ]
      )

      result = described_class.new(
        channel.inbox,
        template_name: 'alerta_movimentacao_processual_v2'
      ).status

      expect(result).to include(
        template_name: 'alerta_movimentacao_processual_v2',
        template_status: 'missing',
        template_header_format: 'IMAGE',
        template_header_media_url: 'https://jusmonitoria.witdev.com.br/jusmonitorialogo.png',
        template_footer_text: 'JusMonitorIA — O Futuro da Inteligência Jurídica®',
        delivery_locked: true
      )
      expect(result[:available_templates]).to include(
        hash_including(
          name: 'alerta_movimentacao_processual_v2',
          version: 2,
          status: 'missing',
          header_format: 'IMAGE',
          header_media_url: 'https://jusmonitoria.witdev.com.br/jusmonitorialogo.png',
          footer_text: 'JusMonitorIA — O Futuro da Inteligência Jurídica®'
        )
      )
    end

    it 'reports Meta rejection reason and parameter format for rejected templates' do
      channel = create(
        :channel_whatsapp,
        account: account,
        provider: 'whatsapp_cloud',
        sync_templates: false,
        validate_provider_config: false,
        message_templates: [
          {
            'id' => 'template_rejected',
            'name' => 'alerta_movimentacao_processual_v1',
            'language' => 'pt_BR',
            'category' => 'UTILITY',
            'parameter_format' => 'POSITIONAL',
            'rejected_reason' => 'INVALID_FORMAT',
            'status' => 'REJECTED'
          }
        ]
      )

      result = described_class.new(channel.inbox).status

      expect(result).to include(
        template_status: 'rejected',
        rejected_reason: 'INVALID_FORMAT',
        template_parameter_format: 'POSITIONAL',
        delivery_locked: true
      )
    end

    it 'fetches Meta review details when the local template cache has no rejection reason' do
      channel = create(
        :channel_whatsapp,
        account: account,
        provider: 'whatsapp_cloud',
        sync_templates: false,
        validate_provider_config: false,
        message_templates: [
          {
            'id' => 'template_rejected',
            'name' => 'alerta_movimentacao_processual_v1',
            'language' => 'pt_BR',
            'category' => 'UTILITY',
            'parameter_format' => 'POSITIONAL',
            'status' => 'REJECTED'
          }
        ]
      )
      stub_request(
        :get,
        'https://graph.facebook.com/v22.0/123456789/message_templates?fields=id,name,status,category,language,rejected_reason,components,parameter_format,quality_score&name=alerta_movimentacao_processual_v1'
      ).to_return(
        status: 200,
        body: {
          data: [
            {
              id: 'template_rejected',
              name: 'alerta_movimentacao_processual_v1',
              language: 'pt_BR',
              category: 'UTILITY',
              parameter_format: 'POSITIONAL',
              rejected_reason: 'INVALID_FORMAT',
              status: 'REJECTED'
            }
          ]
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

      result = described_class.new(channel.inbox).status

      expect(result).to include(
        rejected_reason: 'INVALID_FORMAT',
        template_parameter_format: 'POSITIONAL'
      )
    end
  end

  describe '#create' do
    it 'creates the fixed Utility template with the lista_processos variable' do
      channel = create(
        :channel_whatsapp,
        account: account,
        provider: 'whatsapp_cloud',
        sync_templates: false,
        validate_provider_config: false,
        message_templates: []
      )
      template_creator = instance_double(Whatsapp::TemplateCreatorService)

      expect(Whatsapp::TemplateCreatorService).to receive(:new).with(channel).and_return(template_creator)
      expect(template_creator).to receive(:create_template).with(
        hash_including(
          name: 'alerta_movimentacao_processual_v1',
          category: 'UTILITY',
          language: 'pt_BR',
          parameter_format: 'NAMED',
          body_text: include('{{lista_processos}}')
        )
      ).and_return(
        success: true,
        template_id: 'template_456',
        template_name: 'alerta_movimentacao_processual_v1',
        language: 'pt_BR',
        category: 'UTILITY',
        status: 'PENDING'
      )

      result = described_class.new(channel.inbox).create

      expect(result).to include(
        provider: 'whatsapp_cloud',
        template_required: true,
        template_name: 'alerta_movimentacao_processual_v1',
        category: 'UTILITY',
        requested_category: 'UTILITY',
        template_category: 'UTILITY',
        language: 'pt_BR',
        template_status: 'pending',
        delivery_locked: true,
        created: true,
        template_id: 'template_456'
      )
    end

    it 'creates v2 only when explicitly requested and includes image header and footer metadata' do
      channel = create(
        :channel_whatsapp,
        account: account,
        provider: 'whatsapp_cloud',
        sync_templates: false,
        validate_provider_config: false,
        message_templates: []
      )
      template_creator = instance_double(Whatsapp::TemplateCreatorService)

      expect(Whatsapp::TemplateCreatorService).to receive(:new).with(channel).and_return(template_creator)
      expect(template_creator).to receive(:create_template).with(
        hash_including(
          name: 'alerta_movimentacao_processual_v2',
          category: 'UTILITY',
          language: 'pt_BR',
          parameter_format: 'NAMED',
          header_format: 'IMAGE',
          header_media_url: 'https://jusmonitoria.witdev.com.br/jusmonitorialogo.png',
          footer_text: 'JusMonitorIA — O Futuro da Inteligência Jurídica®',
          allow_category_change: false,
          body_text: include('{{lista_processos}}')
        )
      ).and_return(
        success: true,
        template_id: 'template_v2',
        template_name: 'alerta_movimentacao_processual_v2',
        language: 'pt_BR',
        category: 'UTILITY',
        parameter_format: 'NAMED',
        status: 'PENDING'
      )

      result = described_class.new(
        channel.inbox,
        template_name: 'alerta_movimentacao_processual_v2'
      ).create

      expect(result).to include(
        template_name: 'alerta_movimentacao_processual_v2',
        template_status: 'pending',
        template_id: 'template_v2',
        template_header_format: 'IMAGE',
        template_header_media_url: 'https://jusmonitoria.witdev.com.br/jusmonitorialogo.png',
        template_footer_text: 'JusMonitorIA — O Futuro da Inteligência Jurídica®'
      )
    end

    it 'edits a rejected fixed template before deleting it' do
      channel = create(
        :channel_whatsapp,
        account: account,
        provider: 'whatsapp_cloud',
        sync_templates: false,
        validate_provider_config: false,
        message_templates: [
          {
            'id' => 'template_rejected',
            'name' => 'alerta_movimentacao_processual_v1',
            'language' => 'pt_BR',
            'category' => 'UTILITY',
            'parameter_format' => 'POSITIONAL',
            'rejected_reason' => 'INVALID_FORMAT',
            'status' => 'REJECTED'
          }
        ]
      )
      template_creator = instance_double(Whatsapp::TemplateCreatorService)

      expect(Whatsapp::TemplateCreatorService).to receive(:new).with(channel).and_return(template_creator)
      expect(template_creator).to receive(:update_template).with(
        'template_rejected',
        hash_including(
          name: 'alerta_movimentacao_processual_v1',
          category: 'UTILITY',
          language: 'pt_BR',
          parameter_format: 'NAMED',
          body_text: include('{{lista_processos}}')
        )
      ).and_return(
        success: true,
        template_id: 'template_rejected',
        template_name: 'alerta_movimentacao_processual_v1',
        language: 'pt_BR',
        category: 'UTILITY',
        parameter_format: 'NAMED',
        status: 'PENDING'
      )

      result = described_class.new(channel.inbox).create

      expect(result).to include(
        template_status: 'pending',
        template_id: 'template_rejected',
        template_parameter_format: 'NAMED',
        recreated_after_rejection: true
      )
    end

    it 'falls back to delete and recreate when rejected template edit fails' do
      channel = create(
        :channel_whatsapp,
        account: account,
        provider: 'whatsapp_cloud',
        sync_templates: false,
        validate_provider_config: false,
        message_templates: [
          {
            'id' => 'template_rejected',
            'name' => 'alerta_movimentacao_processual_v1',
            'language' => 'pt_BR',
            'category' => 'UTILITY',
            'parameter_format' => 'POSITIONAL',
            'rejected_reason' => 'INVALID_FORMAT',
            'status' => 'REJECTED'
          }
        ]
      )
      template_creator = instance_double(Whatsapp::TemplateCreatorService)

      stub_request(
        :delete,
        'https://graph.facebook.com/v22.0/123456789/message_templates?name=alerta_movimentacao_processual_v1'
      ).to_return(status: 200, body: { success: true }.to_json)
      expect(Whatsapp::TemplateCreatorService).to receive(:new).with(channel).and_return(template_creator).twice
      expect(template_creator).to receive(:update_template).and_return(
        success: false,
        error: 'Template update failed'
      )
      expect(template_creator).to receive(:create_template).and_return(
        success: true,
        template_id: 'template_recreated',
        template_name: 'alerta_movimentacao_processual_v1',
        language: 'pt_BR',
        category: 'UTILITY',
        parameter_format: 'NAMED',
        status: 'PENDING'
      )

      result = described_class.new(channel.inbox).create

      expect(result).to include(
        template_status: 'pending',
        template_id: 'template_recreated',
        template_parameter_format: 'NAMED',
        recreated_after_rejection: true
      )
    end
  end
end
