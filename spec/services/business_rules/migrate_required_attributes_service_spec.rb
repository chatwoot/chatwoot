# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BusinessRules::MigrateRequiredAttributesService do
  describe '.perform!' do
    it 'creates a require_attributes_on_status rule from legacy keys' do
      account = create(:account)
      account.update!(
        settings: {
          'conversation_required_attributes' => %w[status_sale amount]
        }
      )

      result = described_class.perform!

      expect(result[:migrated]).to eq(1)
      rules = account.reload.settings['business_rules']
      rule = rules.find { |r| r['id'] == described_class::RULE_ID }
      expect(rule['type']).to eq('require_attributes_on_status')
      expect(rule['config']['status']).to eq('resolved')
      expect(rule['config']['attribute_keys']).to match_array(%w[status_sale amount])
    end

    it 'skips when an equivalent enabled rule already exists' do
      account = create(:account)
      account.update!(
        settings: {
          'conversation_required_attributes' => %w[status_sale],
          'business_rules' => [
            {
              'id' => 'other',
              'type' => 'require_attributes_on_status',
              'enabled' => true,
              'config' => { 'status' => 'resolved', 'attribute_keys' => %w[status_sale] }
            }
          ]
        }
      )

      expect { described_class.perform! }.not_to(change { account.reload.settings['business_rules'].size })
    end
  end
end
