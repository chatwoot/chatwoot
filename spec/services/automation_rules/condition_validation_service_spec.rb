require 'rails_helper'

RSpec.describe AutomationRules::ConditionValidationService do
  let(:account) { create(:account) }
  let(:rule) { create(:automation_rule, account: account) }

  describe '#perform' do
    context 'with standard attributes' do
      before do
        rule.conditions = [
          { 'values': ['open'], 'attribute_key': 'status', 'query_operator': nil, 'filter_operator': 'equal_to' },
          { 'values': ['+918484'], 'attribute_key': 'phone_number', 'query_operator': 'OR', 'filter_operator': 'contains' },
          { 'values': ['test'], 'attribute_key': 'email', 'query_operator': nil, 'filter_operator': 'contains' }
        ]
        rule.save # rubocop:disable Rails/SaveBang
      end

      it 'returns true' do
        expect(described_class.new(rule).perform).to be(true)
      end
    end

    context 'with wrong attribute' do
      before do
        rule.conditions = [
          { 'values': ['open'], 'attribute_key': 'not-a-standard-attribute-for-sure', 'query_operator': nil, 'filter_operator': 'equal_to' }
        ]
        rule.save # rubocop:disable Rails/SaveBang
      end

      it 'returns false' do
        expect(described_class.new(rule).perform).to be(false)
      end
    end

    context 'with wrong filter operator' do
      before do
        rule.conditions = [
          { 'values': ['open'], 'attribute_key': 'status', 'query_operator': nil, 'filter_operator': 'not-a-filter-operator' }
        ]
        rule.save # rubocop:disable Rails/SaveBang
      end

      it 'returns false' do
        expect(described_class.new(rule).perform).to be(false)
      end
    end

    context 'with wrong query operator' do
      before do
        rule.conditions = [{ 'values': ['open'], 'attribute_key': 'status', 'query_operator': 'invalid', 'filter_operator': 'attribute_changed' }]
        rule.save # rubocop:disable Rails/SaveBang
      end

      it 'returns false' do
        expect(described_class.new(rule).perform).to be(false)
      end
    end

    context 'with "attribute_changed" filter operator' do
      before do
        rule.conditions = [
          { 'values': ['open'], 'attribute_key': 'status', 'query_operator': nil, 'filter_operator': 'attribute_changed' }
        ]
        rule.save # rubocop:disable Rails/SaveBang
      end

      it 'returns true' do
        expect(described_class.new(rule).perform).to be(true)
      end
    end

    context 'with correct custom attribute' do
      before do
        create(:custom_attribute_definition,
               attribute_key: 'custom_attr_priority',
               account: account,
               attribute_model: 'conversation_attribute',
               attribute_display_type: 'list',
               attribute_values: %w[P0 P1 P2])

        rule.conditions = [
          {
            'values': ['true'],
            'attribute_key': 'custom_attr_priority',
            'filter_operator': 'equal_to',
            'custom_attribute_type': 'conversation_attribute'
          }
        ]
        rule.save # rubocop:disable Rails/SaveBang
      end

      it 'returns true' do
        expect(described_class.new(rule).perform).to be(true)
      end
    end

    context 'with missing custom attribute' do
      before do
        rule.conditions = [
          {
            'values': ['true'],
            'attribute_key': 'attribute_is_not_present', # the attribute is not present
            'filter_operator': 'equal_to',
            'custom_attribute_type': 'conversation_attribute'
          }
        ]
        rule.save # rubocop:disable Rails/SaveBang
      end

      it 'returns false for missing custom attribute' do
        expect(described_class.new(rule).perform).to be(false)
      end
    end
  end
end
