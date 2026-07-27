# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BusinessRules::RequiredAttributeKeys do
  let(:account) { create(:account) }

  it 'returns explicit keys when categories are blank' do
    expect(
      described_class.resolve(account: account, attribute_keys: %w[a b], attribute_category_keys: [])
    ).to eq(%w[a b])
  end

  it 'unions keys from matching categories and excludes formulas' do
    create(:custom_attribute_definition,
           account: account,
           attribute_model: :conversation_attribute,
           attribute_key: 'a1',
           attribute_display_name: 'A1',
           category: 'Venta')
    create(:custom_attribute_definition,
           account: account,
           attribute_model: :conversation_attribute,
           attribute_key: 'a2',
           attribute_display_name: 'A2',
           category: 'Venta',
           formula: { 'op' => 'sum', 'source_attribute_key' => 'a1', 'source_model' => 'self' })

    keys = described_class.resolve(
      account: account,
      attribute_keys: ['extra'],
      attribute_category_keys: ['Venta']
    )

    expect(keys).to include('extra', 'a1')
    expect(keys).not_to include('a2')
  end
end
