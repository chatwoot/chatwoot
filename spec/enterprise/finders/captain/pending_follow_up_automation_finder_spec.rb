require 'rails_helper'

RSpec.describe Captain::PendingFollowUpAutomationFinder do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:connected_inbox) { create(:inbox, account: account) }
  let(:other_inbox) { create(:inbox, account: account) }
  let(:pending_condition) do
    { 'attribute_key' => 'status', 'filter_operator' => 'equal_to', 'values' => ['pending'], 'query_operator' => nil }
  end
  let(:send_message_action) { { 'action_name' => 'send_message', 'action_params' => ['Are you still there?'] } }
  let(:send_attachment_action) { { 'action_name' => 'send_attachment', 'action_params' => [123] } }
  let(:customer_unresponsive_conditions) do
    [
      { 'attribute_key' => 'message_type', 'filter_operator' => 'equal_to',
        'values' => ['outgoing'], 'query_operator' => 'and' },
      { 'attribute_key' => 'private_note', 'filter_operator' => 'equal_to',
        'values' => [false], 'query_operator' => 'and' },
      { 'attribute_key' => 'inbox_id', 'filter_operator' => 'equal_to',
        'values' => [connected_inbox.id], 'query_operator' => nil }
    ]
  end

  before do
    account.enable_features!('delayed_automations')
    create(:captain_inbox, captain_assistant: assistant, inbox: connected_inbox)
  end

  def create_inbox_scoped_follow_up(operator:, inbox_ids: [], execution_delay: 60)
    create(
      :automation_rule,
      account: account,
      event_name: 'conversation_updated',
      execution_delay: execution_delay,
      conditions: [
        pending_condition.merge('query_operator' => 'and'),
        { 'attribute_key' => 'inbox_id', 'filter_operator' => operator,
          'values' => inbox_ids, 'query_operator' => nil }
      ],
      actions: [send_message_action]
    )
  end

  it 'returns active pending follow ups that apply to a connected inbox' do
    account_rule = create(:automation_rule, account: account, event_name: 'conversation_updated', execution_delay: 60,
                                            conditions: [pending_condition], actions: [send_message_action])
    inbox_rule = create(:automation_rule, account: account, event_name: 'message_created', execution_delay: 120,
                                          conditions: customer_unresponsive_conditions,
                                          actions: [send_message_action])
    create(:automation_rule, account: account, event_name: 'conversation_updated', execution_delay: 180,
                             conditions: [pending_condition.merge('query_operator' => 'AND'),
                                          { 'attribute_key' => 'inbox_id', 'filter_operator' => 'equal_to',
                                            'values' => [other_inbox.id], 'query_operator' => nil }],
                             actions: [send_message_action])

    expect(described_class.new(assistant).perform).to contain_exactly(account_rule, inbox_rule)
  end

  it 'returns pending attachment follow ups' do
    attachment_rule = create(:automation_rule, account: account, event_name: 'conversation_updated', execution_delay: 60,
                                               conditions: [pending_condition], actions: [send_attachment_action])

    expect(described_class.new(assistant).perform).to contain_exactly(attachment_rule)
  end

  it 'returns follow ups whose inbox exclusions and presence filters include a connected inbox' do
    excluded_other_inbox_rule = create_inbox_scoped_follow_up(
      operator: 'not_equal_to', inbox_ids: [other_inbox.id]
    )
    inbox_present_rule = create_inbox_scoped_follow_up(
      operator: 'is_present', execution_delay: 120
    )
    create_inbox_scoped_follow_up(
      operator: 'not_equal_to', inbox_ids: [connected_inbox.id], execution_delay: 180
    )
    create_inbox_scoped_follow_up(operator: 'is_not_present', execution_delay: 240)

    expect(described_class.new(assistant).perform).to contain_exactly(excluded_other_inbox_rule, inbox_present_rule)
  end

  it 'ignores rules that cannot send a pending follow up' do
    create(:automation_rule, account: account, event_name: 'conversation_updated', execution_delay: 60, active: false,
                             conditions: [pending_condition], actions: [send_message_action])
    create(:automation_rule, account: account, event_name: 'conversation_updated', execution_delay: 60,
                             conditions: [pending_condition.merge('values' => ['open'])], actions: [send_message_action])
    create(:automation_rule, account: account, event_name: 'conversation_updated', execution_delay: 60,
                             conditions: [pending_condition], actions: [{ 'action_name' => 'add_label', 'action_params' => ['stale'] }])
    create(:automation_rule, account: account, event_name: 'message_created', execution_delay: 60,
                             conditions: customer_unresponsive_conditions.map do |condition|
                               condition['attribute_key'] == 'message_type' ? condition.merge('values' => ['incoming']) : condition
                             end,
                             actions: [send_message_action])

    expect(described_class.new(assistant).perform).to be_empty
  end
end
