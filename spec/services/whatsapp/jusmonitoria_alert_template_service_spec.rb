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
            'status' => 'APPROVED'
          }
        ]
      )

      result = described_class.new(channel.inbox).status

      expect(result).to include(
        category: 'UTILITY',
        requested_category: 'UTILITY',
        template_category: 'MARKETING',
        template_status: 'approved',
        delivery_locked: false
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
  end
end
