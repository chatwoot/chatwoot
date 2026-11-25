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

  context 'when the wait is about inactivity' do
    let(:inactivity_rule) do
      create(:automation_rule, account: account, event_name: 'conversation_updated', execution_delay: 60,
                               execution_delay_trigger: 'inactivity',
                               conditions: [{ 'values' => [conversation.inbox_id], 'attribute_key' => 'inbox_id',
                                              'query_operator' => nil, 'filter_operator' => 'equal_to' }],
                               actions: [{ 'action_name' => 'remove_assigned_agent', 'action_params' => [] }])
    end
    let(:inactivity_execution) do
      AutomationRulePendingExecution.schedule(rule: inactivity_rule, conversation: conversation)
      AutomationRulePendingExecution.last.tap { |row| row.update!(due_at: 1.minute.ago) }
    end

    it 'runs the actions when the conversation really did go quiet' do
      conversation

      travel_to(61.minutes.from_now) do
        AutomationRulePendingExecution.schedule(rule: inactivity_rule, conversation: conversation.reload)
        row = AutomationRulePendingExecution.last

        job.perform(row)

        expect(row.reload).to be_executed
      end
    end

    # The arm anchors on the activity itself, so the two timestamps are equal when the row comes due.
    # Reading that as "something happened after the arm" would push the row forward for ever and the
    # actions would never run.
    it 'fires on the activity it was armed from instead of rescheduling itself' do
      conversation
      message = travel_to(61.minutes.ago) do
        create(:message, conversation: conversation, account: account, message_type: :incoming)
      end
      AutomationRulePendingExecution.schedule(rule: inactivity_rule, conversation: conversation.reload, message: message)
      row = AutomationRulePendingExecution.last

      job.perform(row)

      expect(row.reload).to be_executed
    end

    # A custom attribute written by another automation moves updated_at and not last_activity_at,
    # and the event it dispatches is ignored for being automation-originated, so nothing re-arms
    # the row. The clock has to read that write the same way the arm would.
    it 'pushes the clock when the activity landed on updated_at alone' do
      # A conversation that really has been quiet for an hour: the column defaults to the database
      # clock, which travel_to does not move, so the arm would otherwise read the present.
      quiet = travel_to(61.minutes.ago) do
        create(:conversation, account: account, inbox: conversation.inbox, status: :pending,
                              last_activity_at: Time.current)
      end
      travel_to(61.minutes.ago) do
        AutomationRulePendingExecution.schedule(rule: inactivity_rule, conversation: quiet.reload)
      end
      row = AutomationRulePendingExecution.last
      # Written by another automation: it moves updated_at and not last_activity_at, and the event
      # it dispatches is ignored for being automation-originated, so no listener re-arms the row.
      other_rule = create(:automation_rule, account: account, event_name: 'conversation_updated')
      Current.executed_by = other_rule
      quiet.update!(custom_attributes: { 'fechamento' => 'Venda efetivada' })
      Current.reset

      job.perform(row.reload)

      expect(row.reload).to be_pending
      expect(row.due_at).to be_within(5.seconds).of(60.minutes.from_now)
    end

    # The row is `executing` while the actions run, which no re-arm may take away from the worker.
    # The clock still moves, and reading it at the end is what keeps that activity from being lost:
    # the sweep never looks at an executed row again.
    it 'starts the next count from activity that landed while the actions ran' do
      quiet = travel_to(61.minutes.ago) do
        create(:conversation, account: account, inbox: conversation.inbox, status: :pending,
                              last_activity_at: Time.current)
      end
      travel_to(61.minutes.ago) do
        AutomationRulePendingExecution.schedule(rule: inactivity_rule, conversation: quiet.reload)
      end
      row = AutomationRulePendingExecution.last
      allow(AutomationRules::ActionService).to receive(:new) do
        # A message lands while the actions are running: it moves the clock and leaves the row alone.
        reply = create(:message, conversation: quiet, account: account, message_type: :incoming)
        AutomationRulePendingExecution.schedule(rule: inactivity_rule, conversation: quiet.reload, message: reply)
        instance_double(AutomationRules::ActionService, perform: true)
      end

      job.perform(row.reload)

      expect(row.reload).to be_pending
      expect(row.due_at).to be_within(5.seconds).of(60.minutes.from_now)
    end

    # The deadline the run consumes is the one it started on, not the one it was enqueued with. Kept
    # from before the start, activity this run already accounted for reads as new when it settles,
    # and the actions happen a second time on the next sweep.
    it 'does not settle against a deadline the run itself replaced' do
      quiet = travel_to(70.minutes.ago) do
        create(:conversation, account: account, inbox: conversation.inbox, status: :pending,
                              last_activity_at: Time.current)
      end
      travel_to(70.minutes.ago) do
        AutomationRulePendingExecution.schedule(rule: inactivity_rule, conversation: quiet.reload)
      end
      row = AutomationRulePendingExecution.last
      allow(AutomationRules::ConditionsFilterService).to receive(:new) do
        # A backlogged event lands while the conditions are being asked, and the wait it moves the
        # deadline to is already over.
        AutomationRulePendingExecution.find(row.id).record_activity(65.minutes.ago)
        instance_double(AutomationRules::ConditionsFilterService, perform: [quiet])
      end

      job.perform(row.reload)

      expect(row.reload).to be_executed
    end

    # The clock moves by less than the wait had left on ordinary paths: an arm anchored on a message
    # and the write that message makes to the conversation land a moment apart. Handing the row back
    # for that costs a whole sweep to reach the same answer, so the wait runs late for no reason.
    it 'runs the actions when the recomputed deadline has already elapsed' do
      quiet = travel_to(70.minutes.ago) do
        create(:conversation, account: account, inbox: conversation.inbox, status: :pending,
                              last_activity_at: Time.current)
      end
      travel_to(70.minutes.ago) do
        AutomationRulePendingExecution.schedule(rule: inactivity_rule, conversation: quiet.reload)
      end
      # Five minutes later something touched the conversation, which still leaves the wait over.
      travel_to(65.minutes.ago) { quiet.update!(last_activity_at: Time.current) }
      row = AutomationRulePendingExecution.last

      job.perform(row.reload)

      expect(row.reload).to be_executed
      expect(row.due_at).to be_within(5.seconds).of(5.minutes.ago)
    end

    # Everything between the claim and the actions is a decision, not an action, and the arm cannot
    # take a claimed row back. Without a last look the customer replies and is unassigned in the
    # same breath, which is the one thing the wait promises not to do.
    it 'does not run the actions when activity landed while this worker was deciding' do
      quiet = travel_to(61.minutes.ago) do
        create(:conversation, account: account, inbox: conversation.inbox, status: :pending,
                              last_activity_at: Time.current)
      end
      travel_to(61.minutes.ago) do
        AutomationRulePendingExecution.schedule(rule: inactivity_rule, conversation: quiet.reload)
      end
      row = AutomationRulePendingExecution.last
      allow(AutomationRules::ConditionsFilterService).to receive(:new) do
        # The conditions still match, and the customer writes while that is being asked.
        AutomationRulePendingExecution.find(row.id).record_activity(Time.current)
        instance_double(AutomationRules::ConditionsFilterService, perform: [quiet])
      end
      expect(AutomationRules::ActionService).not_to receive(:new)

      job.perform(row.reload)

      expect(row.reload).to be_pending
      expect(row.due_at).to be_within(5.seconds).of(60.minutes.from_now)
    end

    # A skip is as terminal as a run, and nothing sweeps a terminal row again, so activity recorded
    # while this worker was deciding to skip would be buried with the skip.
    it 'returns the row to pending when activity landed while a skip was being decided' do
      quiet = travel_to(61.minutes.ago) do
        create(:conversation, account: account, inbox: conversation.inbox, status: :pending,
                              last_activity_at: Time.current)
      end
      travel_to(61.minutes.ago) do
        AutomationRulePendingExecution.schedule(rule: inactivity_rule, conversation: quiet.reload)
      end
      row = AutomationRulePendingExecution.last
      allow(AutomationRules::ConditionsFilterService).to receive(:new) do
        # The conditions stopped matching, so this run is about to skip -- and a message lands while
        # that is being decided, which moves the clock and leaves the claimed row alone.
        AutomationRulePendingExecution.find(row.id).record_activity(Time.current)
        instance_double(AutomationRules::ConditionsFilterService, perform: [])
      end

      job.perform(row.reload)

      expect(row.reload).to be_pending
      expect(row.due_at).to be_within(5.seconds).of(60.minutes.from_now)
    end

    # The actions write to the conversation: a private note, a reopen and an unassign are all
    # messages, and a message moves last_activity_at. Counting that as activity would arm the rule
    # against its own run, and a rule scoped to an inbox would act again every delay, for ever.
    it 'does not read its own actions as the activity that restarts the count' do
      quiet = travel_to(61.minutes.ago) do
        create(:conversation, account: account, inbox: conversation.inbox, status: :pending,
                              last_activity_at: Time.current)
      end
      noting_rule = create(:automation_rule, account: account, event_name: 'conversation_updated',
                                             execution_delay: 60, execution_delay_trigger: 'inactivity',
                                             conditions: [{ 'values' => [quiet.inbox_id], 'attribute_key' => 'inbox_id',
                                                            'query_operator' => nil, 'filter_operator' => 'equal_to' }],
                                             actions: [{ 'action_name' => 'add_private_note',
                                                         'action_params' => ['Released for rework'] }])
      travel_to(61.minutes.ago) do
        AutomationRulePendingExecution.schedule(rule: noting_rule, conversation: quiet.reload)
      end
      row = AutomationRulePendingExecution.last

      job.perform(row.reload)

      expect(quiet.messages.where(private: true).count).to eq(1)
      expect(row.reload).to be_executed
    end

    # An activity message and a reply another automation sent both bump last_activity_at without
    # reaching a listener, so the clock is read here instead of trusted from the arm.
    it 'pushes the clock instead of firing when something touched the conversation after the arm' do
      inactivity_execution
      conversation.update!(last_activity_at: Time.current)

      job.perform(inactivity_execution.reload)

      expect(inactivity_execution.reload).to be_pending
      expect(inactivity_execution.due_at).to be_within(5.seconds).of(60.minutes.from_now)
      expect(conversation.reload.assignee_id).to be_nil
    end
  end

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
