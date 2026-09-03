require 'rails_helper'

# Tests for automation conditions that match NULL (empty) field values.
# Regression coverage for: https://github.com/chatwoot/chatwoot/issues/12797
#
# Root cause: the priority "None" option is stored as `nil`. Binding nil into
# `IN (NULL)` always returns FALSE in SQL. The fix emits `IS NULL` / `IS NOT
# NULL` instead.
RSpec.describe AutomationRules::ConditionsFilterService do
  let(:account) { create(:account) }
  let(:inbox)   { create(:inbox, account: account) }
  let(:contact) { create(:contact, account: account) }

  # Helper: build a single-condition rule and run the service against a conversation
  def run_service(conversation, conditions)
    rule = create(
      :automation_rule,
      account: account,
      event_name: 'conversation_created',
      conditions: conditions
    )
    described_class.new(rule, conversation).perform
  end

  # ---------------------------------------------------------------------------
  # priority = nil
  # ---------------------------------------------------------------------------
  describe 'priority condition' do
    context 'when filter_operator is equal_to and value is nil' do
      it 'matches a conversation with no priority set (NULL)' do
        conversation = create(:conversation, account: account, inbox: inbox, contact: contact, priority: nil)
        conditions = [{ 'attribute_key' => 'priority', 'filter_operator' => 'equal_to',
                        'values' => ['nil'], 'query_operator' => nil }]
        expect(run_service(conversation, conditions)).to be true
      end

      it 'does not match a conversation that has a priority set' do
        conversation = create(:conversation, account: account, inbox: inbox, contact: contact, priority: :medium)
        conditions = [{ 'attribute_key' => 'priority', 'filter_operator' => 'equal_to',
                        'values' => ['nil'], 'query_operator' => nil }]
        expect(run_service(conversation, conditions)).to be false
      end
    end

    context 'when filter_operator is not_equal_to and value is nil' do
      it 'matches a conversation that has any priority set' do
        conversation = create(:conversation, account: account, inbox: inbox, contact: contact, priority: :high)
        conditions = [{ 'attribute_key' => 'priority', 'filter_operator' => 'not_equal_to',
                        'values' => ['nil'], 'query_operator' => nil }]
        expect(run_service(conversation, conditions)).to be true
      end

      it 'does not match a conversation with no priority (NULL)' do
        conversation = create(:conversation, account: account, inbox: inbox, contact: contact, priority: nil)
        conditions = [{ 'attribute_key' => 'priority', 'filter_operator' => 'not_equal_to',
                        'values' => ['nil'], 'query_operator' => nil }]
        expect(run_service(conversation, conditions)).to be false
      end
    end

    context 'when priority has a real value (regression: non-null path unchanged)' do
      it 'still matches on equal_to with a real priority value' do
        conversation = create(:conversation, account: account, inbox: inbox, contact: contact, priority: :medium)
        conditions = [{ 'attribute_key' => 'priority', 'filter_operator' => 'equal_to',
                        'values' => ['medium'], 'query_operator' => nil }]
        expect(run_service(conversation, conditions)).to be true
      end
    end
  end

  # ---------------------------------------------------------------------------
  # AND compound condition: priority = nil AND status = open
  # ---------------------------------------------------------------------------
  describe 'compound AND condition with a NULL field' do
    it 'matches when both conditions are satisfied' do
      conversation = create(:conversation, account: account, inbox: inbox, contact: contact,
                             priority: nil, status: :open)
      conditions = [
        { 'attribute_key' => 'priority', 'filter_operator' => 'equal_to',
          'values' => ['nil'], 'query_operator' => 'AND' },
        { 'attribute_key' => 'status', 'filter_operator' => 'equal_to',
          'values' => ['open'], 'query_operator' => nil }
      ]
      expect(run_service(conversation, conditions)).to be true
    end

    it 'does not match when the NULL condition is not met' do
      conversation = create(:conversation, account: account, inbox: inbox, contact: contact,
                             priority: :low, status: :open)
      conditions = [
        { 'attribute_key' => 'priority', 'filter_operator' => 'equal_to',
          'values' => ['nil'], 'query_operator' => 'AND' },
        { 'attribute_key' => 'status', 'filter_operator' => 'equal_to',
          'values' => ['open'], 'query_operator' => nil }
      ]
      expect(run_service(conversation, conditions)).to be false
    end
  end
end
