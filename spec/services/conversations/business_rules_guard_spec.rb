# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Conversations::BusinessRulesGuard do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account, status: :open) }

  def set_rules(rules)
    account.update!(settings: account.settings.merge('business_rules' => rules))
  end

  describe '#perform' do
    it 'blocks resolve when required attributes are missing' do
      set_rules([
                  {
                    'id' => 'r1',
                    'type' => 'require_attributes_on_status',
                    'enabled' => true,
                    'config' => { 'status' => 'resolved', 'attribute_keys' => ['deal_stage'] }
                  }
                ])

      result = described_class.new(conversation: conversation, new_status: 'resolved').perform

      expect(result.ok?).to be(false)
      expect(result.errors).to include(
        hash_including(code: 'require_attributes_on_status', attribute_key: 'deal_stage',
                       attribute_model: 'conversation')
      )
    end

    it 'allows resolve when required attributes are present' do
      conversation.update!(custom_attributes: { 'deal_stage' => 'won' })
      set_rules([
                  {
                    'id' => 'r1',
                    'type' => 'require_attributes_on_status',
                    'enabled' => true,
                    'config' => { 'status' => 'resolved', 'attribute_keys' => ['deal_stage'] }
                  }
                ])

      result = described_class.new(conversation: conversation, new_status: 'resolved').perform

      expect(result.ok?).to be(true)
      expect(result.errors).to be_empty
    end

    it 'blocks resolve when required contact attributes are missing' do
      set_rules([
                  {
                    'id' => 'r1c',
                    'type' => 'require_attributes_on_status',
                    'enabled' => true,
                    'config' => {
                      'status' => 'resolved',
                      'contact_attribute_keys' => ['documento']
                    }
                  }
                ])

      result = described_class.new(conversation: conversation, new_status: 'resolved').perform

      expect(result.ok?).to be(false)
      expect(result.errors).to include(
        hash_including(code: 'require_attributes_on_status', attribute_key: 'documento',
                       attribute_model: 'contact')
      )
    end

    it 'allows resolve when required contact attributes are present' do
      conversation.contact.update!(custom_attributes: { 'documento' => '123' })
      set_rules([
                  {
                    'id' => 'r1c',
                    'type' => 'require_attributes_on_status',
                    'enabled' => true,
                    'config' => {
                      'status' => 'resolved',
                      'contact_attribute_keys' => ['documento']
                    }
                  }
                ])

      result = described_class.new(conversation: conversation, new_status: 'resolved').perform

      expect(result.ok?).to be(true)
    end

    it 'blocks currency zero as blank when required' do
      create(:custom_attribute_definition,
             account: account,
             attribute_model: :conversation_attribute,
             attribute_key: 'valor_venta',
             attribute_display_type: :currency)
      conversation.update!(custom_attributes: { 'valor_venta' => 0 })
      set_rules([
                  {
                    'id' => 'r0',
                    'type' => 'require_attributes_on_status',
                    'enabled' => true,
                    'config' => { 'status' => 'resolved', 'attribute_keys' => ['valor_venta'] }
                  }
                ])

      result = described_class.new(conversation: conversation, new_status: 'resolved').perform

      expect(result.ok?).to be(false)
      expect(result.errors).to include(hash_including(attribute_key: 'valor_venta'))
    end

    it 'requires extra attributes when if-condition matches' do
      conversation.update!(custom_attributes: { 'tipo' => 'venta' })
      set_rules([
                  {
                    'id' => 'rif',
                    'type' => 'if_attribute_then_require',
                    'enabled' => true,
                    'config' => {
                      'on_status' => 'resolved',
                      'when_attribute' => 'tipo',
                      'when_attribute_model' => 'conversation',
                      'when_values' => ['venta'],
                      'require_attribute_keys' => ['valor_venta'],
                      'require_contact_attribute_keys' => ['documento']
                    }
                  }
                ])

      result = described_class.new(conversation: conversation, new_status: 'resolved').perform

      expect(result.ok?).to be(false)
      expect(result.errors.map { |e| e[:attribute_key] }).to include('valor_venta', 'documento')
    end

    it 'blocks resolve when forbidden label is present' do
      conversation.update!(label_list: ['hold'])
      set_rules([
                  {
                    'id' => 'r2',
                    'type' => 'forbid_status_if',
                    'enabled' => true,
                    'config' => { 'status' => 'resolved', 'label' => 'hold' }
                  }
                ])

      result = described_class.new(conversation: conversation, new_status: 'resolved').perform

      expect(result.ok?).to be(false)
      expect(result.errors).to include(hash_including(code: 'forbid_status_if', label: 'hold'))
    end

    it 'ignores rules with non-hash config instead of raising' do
      set_rules([
                  {
                    'id' => 'r3',
                    'type' => 'require_attributes_on_status',
                    'enabled' => true,
                    'config' => 'not-a-hash'
                  }
                ])

      result = described_class.new(conversation: conversation, new_status: 'resolved').perform

      expect(result.ok?).to be(true)
      expect(result.errors).to be_empty
    end
  end
end
