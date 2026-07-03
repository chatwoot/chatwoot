require 'rails_helper'

RSpec.describe Crm::Ai::AttributeSchemaBuilder do
  let(:account) { create(:account) }

  def create_attribute(key:, model:, type:, label: nil, values: nil)
    create(
      :custom_attribute_definition,
      account: account,
      attribute_key: key,
      attribute_display_name: label || key.humanize,
      attribute_model: model,
      attribute_display_type: type,
      attribute_values: values
    )
  end

  it 'builds contact and conversation schemas with list options only for list attributes' do
    create_attribute(key: 'sw_cidade', model: 'contact_attribute', type: 'text', label: 'Cidade')
    create_attribute(
      key: 'sw_decisor',
      model: 'contact_attribute',
      type: 'list',
      label: 'É decisor?',
      values: ['Sim, decide', 'Há outros decisores']
    )
    create_attribute(key: 'sw_dor_principal', model: 'conversation_attribute', type: 'text', label: 'Dor principal')
    create_attribute(key: 'sw_agenda_confirmada', model: 'conversation_attribute', type: 'checkbox', label: 'Agenda confirmada')
    create_attribute(key: 'other_city', model: 'contact_attribute', type: 'text', label: 'Outra cidade')
    create_attribute(key: 'sw_empresa', model: 'company_attribute', type: 'text', label: 'Empresa')

    schema = described_class.new(account: account, prefix: 'sw_').perform

    expect(schema[:contact]).to contain_exactly(
      { key: 'sw_cidade', label: 'Cidade', type: 'text' },
      { key: 'sw_decisor', label: 'É decisor?', type: 'list', options: ['Sim, decide', 'Há outros decisores'] }
    )
    expect(schema[:conversation]).to contain_exactly(
      { key: 'sw_dor_principal', label: 'Dor principal', type: 'text' },
      { key: 'sw_agenda_confirmada', label: 'Agenda confirmada', type: 'checkbox' }
    )
  end
end
