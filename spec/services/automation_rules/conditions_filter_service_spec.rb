require 'rails_helper'

RSpec.describe AutomationRules::ConditionsFilterService do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:rule) { create(:automation_rule, account: account) }

  before do
    conversation = create(:conversation, account: account)
    conversation.contact.update(phone_number: '+918484828282', email: 'test@test.com')
    create(:conversation, account: account)
    create(:conversation, account: account)
  end

  describe '#perform' do
    context 'when conditions based on filter_operator equal_to' do
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

    context 'when conditions based on filter_operator start_with' do
      before do
        contact = conversation.contact
        contact.update(phone_number: '+918484848484')
        rule.conditions = [
          { 'values': ['+918484'], 'attribute_key': 'phone_number', 'query_operator': 'OR', 'filter_operator': 'starts_with' },
          { 'values': ['test'], 'attribute_key': 'email', 'query_operator': nil, 'filter_operator': 'contains' }
        ]
        rule.save
      end

      context 'when conditions in rule matches with object' do
        it 'will return true' do
          expect(described_class.new(rule, conversation, { changed_attributes: {} }).perform).to be(true)
        end
      end

      context 'when conditions in rule does not match with object' do
        it 'will return false' do
          conversation.contact.update(phone_number: '+918585858585')
          expect(described_class.new(rule, conversation, { changed_attributes: {} }).perform).to be(false)
        end
      end
    end
  end
end
