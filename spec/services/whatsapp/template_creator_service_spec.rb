require 'rails_helper'

RSpec.describe Whatsapp::TemplateCreatorService do
  describe '#build_request_body' do
    it 'sends named body parameter examples for named Meta variables' do
      channel = instance_double(Channel::Whatsapp, provider_config: {})
      service = described_class.new(channel)

      request_body = service.send(
        :build_request_body,
        name: 'alerta_movimentacao_processual_v1',
        language: 'pt_BR',
        category: 'UTILITY',
        body_text: '{{lista_processos}}'
      )

      body_component = request_body[:components].find { |component| component[:type] == 'BODY' }

      expect(body_component[:example]).to eq(
        body_text_named_params: [
          {
            param_name: 'lista_processos',
            example: Whatsapp::TemplateCreatorService::VARIABLE_EXAMPLES['lista_processos']
          }
        ]
      )
    end
  end
end
