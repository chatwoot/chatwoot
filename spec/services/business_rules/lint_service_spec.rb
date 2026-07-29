# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BusinessRules::LintService do
  let(:account) { create(:account) }

  def lint(rules)
    described_class.new(account: account, rules: rules).perform
  end

  it 'allows disabled invalid rules' do
    result = lint([
                    {
                      'id' => 'bad',
                      'type' => 'require_attributes_on_status',
                      'enabled' => false,
                      'name' => 'Bad',
                      'conditions' => [],
                      'config' => { 'status' => 'resolved', 'attribute_keys' => [] }
                    }
                  ])

    expect(result.ok?).to be(true)
    expect(result.errors).to be_empty
  end

  it 'flags impossible AND on the same attribute with disjoint values' do
    result = lint([
                    {
                      'id' => 'envios',
                      'type' => 'if_attribute_then_require',
                      'enabled' => true,
                      'name' => 'Envios',
                      'conditions' => [
                        {
                          'attribute_key' => 'tipo',
                          'filter_operator' => 'equal_to',
                          'values' => ['Venta'],
                          'query_operator' => 'and',
                          'custom_attribute_type' => 'conversation_attribute'
                        },
                        {
                          'attribute_key' => 'tipo',
                          'filter_operator' => 'equal_to',
                          'values' => ['Servicio'],
                          'query_operator' => nil,
                          'custom_attribute_type' => 'conversation_attribute'
                        }
                      ],
                      'config' => {
                        'on_status' => 'resolved',
                        'require_attribute_keys' => ['courier']
                      }
                    }
                  ])

    expect(result.ok?).to be(false)
    expect(result.errors).to include(
      have_attributes(code: 'impossible_and', rule_id: 'envios')
    )
  end

  it 'allows OR of alternate values on the same attribute' do
    create(:custom_attribute_definition,
           account: account,
           attribute_model: :conversation_attribute,
           attribute_key: 'tipo',
           attribute_display_name: 'Tipo')
    create(:custom_attribute_definition,
           account: account,
           attribute_model: :conversation_attribute,
           attribute_key: 'courier',
           attribute_display_name: 'Courier')

    result = lint([
                    {
                      'id' => 'envios',
                      'type' => 'if_attribute_then_require',
                      'enabled' => true,
                      'name' => 'Envios',
                      'conditions' => [
                        {
                          'attribute_key' => 'tipo',
                          'filter_operator' => 'equal_to',
                          'values' => ['Venta'],
                          'query_operator' => 'or',
                          'custom_attribute_type' => 'conversation_attribute'
                        },
                        {
                          'attribute_key' => 'tipo',
                          'filter_operator' => 'equal_to',
                          'values' => ['Servicio'],
                          'custom_attribute_type' => 'conversation_attribute'
                        }
                      ],
                      'config' => {
                        'on_status' => 'resolved',
                        'require_attribute_keys' => ['courier']
                      }
                    }
                  ])

    expect(result.ok?).to be(true)
  end

  it 'flags empty require set when category resolves to no keys' do
    result = lint([
                    {
                      'id' => 'empty',
                      'type' => 'require_attributes_on_status',
                      'enabled' => true,
                      'name' => 'Empty',
                      'conditions' => [],
                      'config' => {
                        'status' => 'resolved',
                        'attribute_keys' => [],
                        'attribute_category_keys' => ['MissingCategory']
                      }
                    }
                  ])

    expect(result.ok?).to be(false)
    expect(result.errors.map(&:code)).to include('empty_require_set', 'unknown_category')
  end

  it 'flags unknown attribute keys' do
    result = lint([
                    {
                      'id' => 'unk',
                      'type' => 'require_attributes_on_status',
                      'enabled' => true,
                      'name' => 'Unknown',
                      'conditions' => [],
                      'config' => {
                        'status' => 'resolved',
                        'attribute_keys' => ['does_not_exist']
                      }
                    }
                  ])

    expect(result.ok?).to be(false)
    expect(result.errors).to include(
      have_attributes(code: 'unknown_attribute_key', rule_id: 'unk')
    )
  end

  it 'flags if_attribute_then_require without trigger' do
    create(:custom_attribute_definition,
           account: account,
           attribute_model: :conversation_attribute,
           attribute_key: 'courier',
           attribute_display_name: 'Courier')

    result = lint([
                    {
                      'id' => 'notrig',
                      'type' => 'if_attribute_then_require',
                      'enabled' => true,
                      'name' => 'No trigger',
                      'conditions' => [],
                      'config' => {
                        'on_status' => 'resolved',
                        'require_attribute_keys' => ['courier']
                      }
                    }
                  ])

    expect(result.ok?).to be(false)
    expect(result.errors).to include(have_attributes(code: 'missing_trigger'))
  end

  it 'flags forbid + require conflict on the same status' do
    create(:custom_attribute_definition,
           account: account,
           attribute_model: :conversation_attribute,
           attribute_key: 'deal_stage',
           attribute_display_name: 'Deal')

    result = lint([
                    {
                      'id' => 'forbid',
                      'type' => 'forbid_status_if',
                      'enabled' => true,
                      'name' => 'Forbid',
                      'conditions' => [],
                      'config' => { 'status' => 'resolved', 'label' => 'blocked' }
                    },
                    {
                      'id' => 'require',
                      'type' => 'require_attributes_on_status',
                      'enabled' => true,
                      'name' => 'Require',
                      'conditions' => [],
                      'config' => {
                        'status' => 'resolved',
                        'attribute_keys' => ['deal_stage']
                      }
                    }
                  ])

    expect(result.ok?).to be(false)
    expect(result.errors).to include(have_attributes(code: 'forbid_conflicts_require'))
  end
end

RSpec.describe BusinessRules::ConditionValues do
  it 'normalizes hash id/name payloads to string arrays' do
    expect(described_class.normalize([{ 'id' => 'Venta', 'name' => 'Venta' }])).to eq(['Venta'])
    expect(described_class.normalize('Servicio')).to eq(['Servicio'])
    expect(described_class.normalize(nil)).to eq([])
  end
end
