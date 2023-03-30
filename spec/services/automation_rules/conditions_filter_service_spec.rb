require 'rails_helper'

RSpec.describe AutomationRules::ConditionsFilterService do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:rule) { create(:automation_rule, account: account) }

  describe '#perform' do
    before do
      rule.conditions = [{ 'values': ['open'], 'attribute_key': 'status', 'query_operator': nil, 'filter_operator': 'equal_to' }]
      rule.save
    end

    context 'when conditions in rule matches with object' do
      it 'will return true' do
        expect(described_class.new(rule, conversation, { changed_attributes: { status: [nil, 'open'] } }).perform).to be(true)
      end
    end

    context 'when conditions in rule does not match with object' do
      it 'will return false' do
        conversation.update(status: 'resolved')
        expect(described_class.new(rule, conversation, { changed_attributes: { status: %w[open resolved] } }).perform).to be(false)
      end
    end
  end

  ## TODO: add tests for the other conditions
end
