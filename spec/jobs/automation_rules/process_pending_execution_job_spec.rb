require 'rails_helper'

RSpec.describe AutomationRules::ProcessPendingExecutionJob do
  subject(:job) { described_class.new }

  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account, status: :pending) }
  let(:rule) do
    create(:automation_rule, account: account, event_name: 'conversation_updated', execution_delay: 60,
                             conditions: [{ 'values' => ['pending'], 'attribute_key' => 'status', 'query_operator' => nil,
                                            'filter_operator' => 'equal_to' }],
                             actions: [{ 'action_name' => 'add_label', 'action_params' => ['stale'] }])
  end
  let(:pending_execution) do
    AutomationRulePendingExecution.schedule(rule: rule, conversation: conversation)
    # The sweep only enqueues due rows, so make it due before the job runs.
    AutomationRulePendingExecution.last.tap { |row| row.update!(due_at: 1.minute.ago) }
  end
  # A reply-chase rule whose action is customer-facing, so a replay is visible as a duplicate message.
  let(:follow_up_rule) do
    create(:automation_rule, account: account, event_name: 'message_created', execution_delay: 60,
                             conditions: [
                               { 'values' => ['outgoing'], 'attribute_key' => 'message_type',
                                 'query_operator' => 'and', 'filter_operator' => 'equal_to' },
                               { 'values' => [false], 'attribute_key' => 'private_note',
                                 'query_operator' => 'and', 'filter_operator' => 'equal_to' },
                               { 'values' => [conversation.inbox_id], 'attribute_key' => 'inbox_id',
                                 'query_operator' => 'and', 'filter_operator' => 'equal_to' },
                               { 'values' => ['pending'], 'attribute_key' => 'status',
                                 'query_operator' => nil, 'filter_operator' => 'equal_to' }
                             ],
                             actions: [{ 'action_name' => 'send_message', 'action_params' => ['Just checking in'] }])
  end
  let(:agent_reply) { create(:message, conversation: conversation, account: account, message_type: :outgoing) }
  let(:follow_up_execution) do
    AutomationRulePendingExecution.schedule(rule: follow_up_rule, conversation: conversation, message: agent_reply)
    AutomationRulePendingExecution.last.tap { |row| row.update!(due_at: 1.minute.ago) }
  end

  before { account.enable_features!('delayed_automations') }

  it 'runs the actions and marks the row executed when every guard passes' do
    job.perform(pending_execution.reload)

    expect(pending_execution.reload).to be_executed
    expect(conversation.reload.label_list).to include('stale')
  end

  it 'skips with rule_inactive when the rule was disabled' do
    rule.update!(active: false)
    job.perform(pending_execution.reload)

    expect(pending_execution.reload).to be_skipped
    expect(pending_execution.skip_reason).to eq('rule_inactive')
    expect(conversation.reload.label_list).to be_empty
  end

  it 'pauses (keeps pending) while the account flag is off, then fires when re-enabled' do
    account.disable_features!('delayed_automations')
    job.perform(pending_execution.reload)

    expect(pending_execution.reload).to be_pending
    expect(conversation.reload.label_list).to be_empty

    account.enable_features!('delayed_automations')
    described_class.new.perform(pending_execution.reload)

    expect(pending_execution.reload).to be_executed
    expect(conversation.reload.label_list).to include('stale')
  end

  it 'skips with episode_moved when the conversation left the armed status' do
    pending_execution
    conversation.update!(status: :resolved)
    job.perform(pending_execution.reload)

    expect(pending_execution.reload).to be_skipped
    expect(pending_execution.skip_reason).to eq('episode_moved')
    expect(conversation.reload.label_list).to be_empty
  end

  it 'skips with conditions_changed when the conversation drifts but the episode is intact' do
    row = follow_up_execution

    # Status change fails the condition but leaves the reply_chase episode (max incoming id) intact.
    conversation.update!(status: :open)
    job.perform(row)

    expect(row.reload).to be_skipped
    expect(row.skip_reason).to eq('conditions_changed')
    expect(conversation.messages.outgoing.where(content: 'Just checking in')).to be_empty
  end

  it 'skips when any excluded label is present at execution time' do
    conditions = follow_up_rule.conditions.deep_dup
    conditions.last['query_operator'] = 'and'
    conditions << {
      'values' => ['feature'], 'attribute_key' => 'labels', 'query_operator' => nil,
      'filter_operator' => 'not_equal_to'
    }
    follow_up_rule.update!(conditions: conditions)
    row = follow_up_execution
    conversation.add_labels(%w[bug feature])

    job.perform(row)

    expect(row.reload).to be_skipped
    expect(row.skip_reason).to eq('conditions_changed')
    expect(conversation.messages.outgoing.where(content: 'Just checking in')).to be_empty
  end

  it 'skips with expired when the row is past the due window' do
    pending_execution.update!(due_at: 4.days.ago)
    job.perform(pending_execution.reload)

    expect(pending_execution.reload).to be_skipped
    expect(pending_execution.skip_reason).to eq('expired')
    expect(conversation.reload.label_list).to be_empty
  end

  it 'runs the actions once when the same row is processed twice concurrently' do
    allow(AutomationRules::ActionService).to receive(:new).and_call_original
    duplicate = AutomationRulePendingExecution.find(pending_execution.id)

    job.perform(pending_execution.reload)
    described_class.new.perform(duplicate)

    expect(AutomationRules::ActionService).to have_received(:new).once
    expect(pending_execution.reload).to be_executed
  end

  it 'leaves the row executing and reports the error when an action blows up' do
    action_service = instance_double(AutomationRules::ActionService)
    allow(AutomationRules::ActionService).to receive(:new).and_return(action_service)
    allow(action_service).to receive(:perform).and_raise(StandardError, 'boom')
    allow(ChatwootExceptionTracker).to receive(:new).and_call_original

    job.perform(pending_execution.reload)

    expect(pending_execution.reload).to be_executing
    expect(ChatwootExceptionTracker).to have_received(:new)
  end

  it 'retries a row that died before the actions and still sends the follow-up exactly once' do
    row = follow_up_execution
    allow(AutomationRules::ConditionsFilterService).to receive(:new).and_raise(StandardError, 'boom')

    job.perform(row.reload)

    expect(row.reload).to be_processing
    expect(conversation.messages.outgoing.pluck(:content)).not_to include('Just checking in')

    allow(AutomationRules::ConditionsFilterService).to receive(:new).and_call_original
    travel_to(20.minutes.from_now) do
      expect(AutomationRulePendingExecution.sweepable).to include(row)
      described_class.new.perform(AutomationRulePendingExecution.find(row.id))
    end

    expect(row.reload).to be_executed
    expect(conversation.messages.outgoing.where(content: 'Just checking in').count).to eq(1)
  end

  it 'never sends the follow-up twice when the row dies after the action ran but before it was marked executed' do
    row = follow_up_execution.reload
    allow(row).to receive(:update!).and_call_original
    allow(row).to receive(:update!).with(status: :executed).and_raise(ActiveRecord::StatementInvalid, 'connection lost')

    job.perform(row)

    # The row is left `executing`, which no sweep reclaims, so the stale retry cannot re-send.
    expect(row.reload).to be_executing
    expect(conversation.messages.outgoing.where(content: 'Just checking in').count).to eq(1)

    travel_to(20.minutes.from_now) do
      expect(AutomationRulePendingExecution.sweepable).not_to include(row)
      expect(AutomationRulePendingExecution.abandoned).to include(row)
      described_class.new.perform(AutomationRulePendingExecution.find(row.id))
    end

    expect(row.reload).to be_executing
    expect(conversation.messages.outgoing.where(content: 'Just checking in').count).to eq(1)
  end

  it 'sends the follow-up exactly once for the reply-chase story' do
    job.perform(follow_up_execution.reload)

    expect(follow_up_execution.reload).to be_executed
    expect(conversation.messages.outgoing.where(content: 'Just checking in').count).to eq(1)
  end

  it 'cancels the follow-up when the customer replied before the arming job ran' do
    agent_reply
    create(:message, conversation: conversation, account: account, message_type: :incoming)
    # Only now does the queued MESSAGE_CREATED job arm the row for the agent's reply.
    row = follow_up_execution

    job.perform(row.reload)

    expect(row.reload).to be_skipped
    expect(row.skip_reason).to eq('episode_moved')
    expect(conversation.messages.outgoing.pluck(:content)).not_to include('Just checking in')
  end

  it 'cancels the follow-up when the customer replied before it was due' do
    row = follow_up_execution
    create(:message, conversation: conversation, account: account, message_type: :incoming)
    job.perform(row.reload)

    expect(row.reload).to be_skipped
    expect(row.skip_reason).to eq('episode_moved')
    expect(conversation.messages.outgoing.pluck(:content)).not_to include('Just checking in')
  end
end
