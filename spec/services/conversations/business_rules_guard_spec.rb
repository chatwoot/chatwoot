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

    it 'expands attribute categories into required keys' do
      create(:custom_attribute_definition,
             account: account,
             attribute_model: :conversation_attribute,
             attribute_key: 'total_venta',
             attribute_display_name: 'Total',
             attribute_display_type: :number,
             category: 'Venta')
      create(:custom_attribute_definition,
             account: account,
             attribute_model: :conversation_attribute,
             attribute_key: 'tipo_venta',
             attribute_display_name: 'Tipo venta',
             attribute_display_type: :text,
             category: 'Venta')

      set_rules([
                  {
                    'id' => 'rcat',
                    'type' => 'require_attributes_on_status',
                    'enabled' => true,
                    'config' => {
                      'status' => 'resolved',
                      'attribute_category_keys' => ['Venta']
                    }
                  }
                ])

      result = described_class.new(conversation: conversation, new_status: 'resolved').perform

      expect(result.ok?).to be(false)
      expect(result.errors.map { |e| e[:attribute_key] }).to include('total_venta', 'tipo_venta')
    end

    it 'skips effect when conditions do not match' do
      set_rules([
                  {
                    'id' => 'rcond',
                    'type' => 'require_attributes_on_status',
                    'enabled' => true,
                    'conditions' => [
                      {
                        'attribute_key' => 'status',
                        'filter_operator' => 'equal_to',
                        'values' => ['pending'],
                        'query_operator' => nil,
                        'custom_attribute_type' => ''
                      }
                    ],
                    'config' => { 'status' => 'resolved', 'attribute_keys' => ['deal_stage'] }
                  }
                ])

      result = described_class.new(conversation: conversation, new_status: 'resolved').perform

      expect(result.ok?).to be(true)
    end

    it 'applies effect when conditions match' do
      set_rules([
                  {
                    'id' => 'rcond2',
                    'type' => 'require_attributes_on_status',
                    'enabled' => true,
                    'conditions' => [
                      {
                        'attribute_key' => 'status',
                        'filter_operator' => 'equal_to',
                        'values' => ['open'],
                        'query_operator' => nil,
                        'custom_attribute_type' => ''
                      }
                    ],
                    'config' => { 'status' => 'resolved', 'attribute_keys' => ['deal_stage'] }
                  }
                ])

      result = described_class.new(conversation: conversation, new_status: 'resolved').perform

      expect(result.ok?).to be(false)
      expect(result.errors).to include(hash_including(attribute_key: 'deal_stage'))
    end

    it 'uses conditions instead of legacy when_* for if_attribute_then_require' do
      conversation.update!(custom_attributes: { 'tipo' => 'otro' })
      set_rules([
                  {
                    'id' => 'rif2',
                    'type' => 'if_attribute_then_require',
                    'enabled' => true,
                    'conditions' => [
                      {
                        'attribute_key' => 'status',
                        'filter_operator' => 'equal_to',
                        'values' => ['open'],
                        'query_operator' => nil,
                        'custom_attribute_type' => ''
                      }
                    ],
                    'config' => {
                      'on_status' => 'resolved',
                      'when_attribute' => 'tipo',
                      'when_values' => ['venta'],
                      'require_attribute_keys' => ['valor_venta']
                    }
                  }
                ])

      result = described_class.new(conversation: conversation, new_status: 'resolved').perform

      expect(result.ok?).to be(false)
      expect(result.errors).to include(hash_including(attribute_key: 'valor_venta'))
    end

    it 'skips guards when status change is driven by an automation' do
      set_rules([
                  {
                    'id' => 'r_reason',
                    'type' => 'require_reason_on_status',
                    'enabled' => true,
                    'config' => {
                      'statuses' => ['snoozed'],
                      'reason_attribute_key' => 'motivo_posponer',
                      'require_private_note' => true
                    }
                  }
                ])

      Current.executed_by = create(:automation_rule, account: account)
      result = described_class.new(conversation: conversation, new_status: 'snoozed').perform

      expect(result.ok?).to be(true)
      expect(result.errors).to be_empty
    ensure
      Current.reset
    end

    it 'skips guards when business_rules_paused is set' do
      set_rules([
                  {
                    'id' => 'r1',
                    'type' => 'require_attributes_on_status',
                    'enabled' => true,
                    'config' => { 'status' => 'resolved', 'attribute_keys' => ['deal_stage'] }
                  }
                ])
      account.update!(settings: account.settings.merge('business_rules_paused' => true))

      result = described_class.new(conversation: conversation, new_status: 'resolved').perform

      expect(result.ok?).to be(true)
      expect(result.errors).to be_empty
    end

    it 'still blocks agents when require_reason_on_status is missing data' do
      set_rules([
                  {
                    'id' => 'r_reason',
                    'type' => 'require_reason_on_status',
                    'enabled' => true,
                    'config' => {
                      'statuses' => ['snoozed'],
                      'reason_attribute_key' => 'motivo_posponer',
                      'require_private_note' => true
                    }
                  }
                ])

      result = described_class.new(conversation: conversation, new_status: 'snoozed').perform

      expect(result.ok?).to be(false)
      expect(result.errors).to include(hash_including(code: 'require_reason_attribute'))
    end

    it 'does not treat inbox bot assignee as satisfying require_assignee_on_status' do
      bot = create(:agent_bot, account: account)
      conversation.update!(assignee_agent_bot: bot, status: :pending)
      set_rules([
                  {
                    'id' => 'r_assignee',
                    'type' => 'require_assignee_on_status',
                    'enabled' => true,
                    'config' => { 'status' => 'open', 'require_team_or_agent' => true }
                  }
                ])

      result = described_class.new(conversation: conversation, new_status: 'open').perform

      expect(result.ok?).to be(false)
      expect(result.errors).to include(hash_including(code: 'require_assignee_on_status'))
    end

    it 'allows require_assignee_on_status when a human agent is assigned' do
      agent = create(:user, account: account, role: :agent)
      conversation.update!(assignee: agent, status: :pending)
      set_rules([
                  {
                    'id' => 'r_assignee',
                    'type' => 'require_assignee_on_status',
                    'enabled' => true,
                    'config' => { 'status' => 'open', 'require_team_or_agent' => true }
                  }
                ])

      result = described_class.new(conversation: conversation, new_status: 'open').perform

      expect(result.ok?).to be(true)
    end
  end
end
