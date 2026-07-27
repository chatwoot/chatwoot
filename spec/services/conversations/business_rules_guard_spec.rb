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
        hash_including(code: 'require_attributes_on_status', attribute_key: 'deal_stage')
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
