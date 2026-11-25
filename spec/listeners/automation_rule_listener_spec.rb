require 'rails_helper'

describe AutomationRuleListener do
  let(:listener) { described_class.instance }
  let!(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:conditions_filter_service) { double }
  let(:condition_match) { double }
  let(:action_service) { double }

  before do
    allow(AutomationRules::ConditionsFilterService).to receive(:new).and_return(conditions_filter_service)
    allow(conditions_filter_service).to receive(:perform).and_return(condition_match)
    allow(AutomationRules::ActionService).to receive(:new).and_return(action_service)
    allow(action_service).to receive(:perform)
  end

  describe 'conversation_created' do
    let!(:automation_rule) { create(:automation_rule, event_name: 'conversation_created', account: account) }
    let(:event) do
      Events::Base.new('conversation_created', Time.zone.now, { conversation: conversation,
                                                                changed_attributes: { status: %w[nil Open] } })
    end

    context 'when matching rules are present' do
      it 'calls AutomationRules::ActionService if conditions match' do
        allow(condition_match).to receive(:present?).and_return(true)
        listener.conversation_created(event)
        expect(AutomationRules::ActionService).to have_received(:new).with(automation_rule, account, conversation)
      end

      it 'does not call AutomationRules::ActionService if conditions do not match' do
        allow(condition_match).to receive(:present?).and_return(false)
        listener.conversation_created(event)
        expect(AutomationRules::ActionService).not_to have_received(:new).with(automation_rule, account, conversation)
      end

      it 'calls AutomationRules::ActionService for each rule when multiple rules are present' do
        create(:automation_rule, event_name: 'conversation_created', account: account)
        allow(condition_match).to receive(:present?).and_return(true)
        listener.conversation_created(event)
        expect(AutomationRules::ActionService).to have_received(:new).twice
      end

      it 'does not call AutomationRules::ActionService if performed by automation' do
        event.data[:performed_by] = automation_rule
        allow(condition_match).to receive(:present?).and_return(true)
        listener.conversation_created(event)
        expect(AutomationRules::ActionService).not_to have_received(:new).with(automation_rule, account, conversation)
      end

      it 'does not call AutomationRules::ActionService if conversation has auto_reply in additional_attributes' do
        conversation.additional_attributes = { 'auto_reply' => true }
        allow(condition_match).to receive(:present?).and_return(true)
        listener.conversation_created(event)
        expect(AutomationRules::ActionService).not_to have_received(:new).with(automation_rule, account, conversation)
      end
    end
  end

  describe 'conversation_updated' do
    let!(:automation_rule) { create(:automation_rule, event_name: 'conversation_updated', account: account) }
    let(:event) do
      Events::Base.new('conversation_updated', Time.zone.now, { conversation: conversation,
                                                                changed_attributes: { status: %w[Resolved Open] } })
    end

    context 'when matching rules are present' do
      it 'calls AutomationRules::ActionService if conditions match' do
        allow(condition_match).to receive(:present?).and_return(true)
        listener.conversation_updated(event)
        expect(AutomationRules::ActionService).to have_received(:new).with(automation_rule, account, conversation)
      end

      it 'does not call AutomationRules::ActionService if conditions do not match' do
        allow(condition_match).to receive(:present?).and_return(false)
        listener.conversation_updated(event)
        expect(AutomationRules::ActionService).not_to have_received(:new).with(automation_rule, account, conversation)
      end

      it 'calls AutomationRules::ActionService for each rule when multiple rules are present' do
        create(:automation_rule, event_name: 'conversation_updated', account: account)
        allow(condition_match).to receive(:present?).and_return(true)
        listener.conversation_updated(event)
        expect(AutomationRules::ActionService).to have_received(:new).twice
      end

      it 'does not call AutomationRules::ActionService if performed by automation' do
        event.data[:performed_by] = automation_rule
        allow(condition_match).to receive(:present?).and_return(true)
        listener.conversation_updated(event)
        expect(AutomationRules::ActionService).not_to have_received(:new).with(automation_rule, account, conversation)
      end
    end
  end

  describe 'conversation_opened' do
    let!(:automation_rule) { create(:automation_rule, event_name: 'conversation_opened', account: account) }
    let(:event) do
      Events::Base.new('conversation_opened', Time.zone.now, { conversation: conversation,
                                                               changed_attributes: { status: %w[Resolved Open] } })
    end

    context 'when matching rules are present' do
      it 'calls AutomationRules::ActionService if conditions match' do
        allow(condition_match).to receive(:present?).and_return(true)
        listener.conversation_opened(event)
        expect(AutomationRules::ActionService).to have_received(:new).with(automation_rule, account, conversation)
      end

      it 'does not call AutomationRules::ActionService if conditions do not match' do
        allow(condition_match).to receive(:present?).and_return(false)
        listener.conversation_opened(event)
        expect(AutomationRules::ActionService).not_to have_received(:new).with(automation_rule, account, conversation)
      end

      it 'calls AutomationRules::ActionService for each rule when multiple rules are present' do
        create(:automation_rule, event_name: 'conversation_opened', account: account)
        allow(condition_match).to receive(:present?).and_return(true)
        listener.conversation_opened(event)
        expect(AutomationRules::ActionService).to have_received(:new).twice
      end

      it 'does not call AutomationRules::ActionService if performed by automation' do
        event.data[:performed_by] = automation_rule
        allow(condition_match).to receive(:present?).and_return(true)
        listener.conversation_opened(event)
        expect(AutomationRules::ActionService).not_to have_received(:new).with(automation_rule, account, conversation)
      end
    end
  end

  describe 'conversation_resolved' do
    let!(:automation_rule) { create(:automation_rule, event_name: 'conversation_resolved', account: account) }
    let(:event) do
      Events::Base.new('conversation_resolved', Time.zone.now, { conversation: conversation,
                                                                 changed_attributes: { status: %w[Snoozed Open] } })
    end

    context 'when matching rules are present' do
      it 'calls AutomationRules::ActionService if conditions match' do
        allow(condition_match).to receive(:present?).and_return(true)
        listener.conversation_resolved(event)
        expect(AutomationRules::ActionService).to have_received(:new).with(automation_rule, account, conversation)
      end

      it 'does not call AutomationRules::ActionService if conditions do not match' do
        allow(condition_match).to receive(:present?).and_return(false)
        listener.conversation_resolved(event)
        expect(AutomationRules::ActionService).not_to have_received(:new).with(automation_rule, account, conversation)
      end

      it 'calls AutomationRules::ActionService for each rule when multiple rules are present' do
        create(:automation_rule, event_name: 'conversation_resolved', account: account)
        allow(condition_match).to receive(:present?).and_return(true)
        listener.conversation_resolved(event)
        expect(AutomationRules::ActionService).to have_received(:new).twice
      end

      it 'does not call AutomationRules::ActionService if performed by automation' do
        event.data[:performed_by] = automation_rule
        allow(condition_match).to receive(:present?).and_return(true)
        listener.conversation_resolved(event)
        expect(AutomationRules::ActionService).not_to have_received(:new).with(automation_rule, account, conversation)
      end
    end
  end

  describe 'message_created' do
    let!(:automation_rule) { create(:automation_rule, event_name: 'message_created', account: account) }
    let!(:message) { create(:message, account: account, conversation: conversation) }
    let(:event) do
      Events::Base.new('message_created', Time.zone.now, { message: message,
                                                           changed_attributes: { content: %w[nil Hi] } })
    end

    context 'when matching rules are present' do
      it 'calls AutomationRules::ActionService if conditions match' do
        allow(condition_match).to receive(:present?).and_return(true)
        listener.message_created(event)
        expect(AutomationRules::ActionService).to have_received(:new).with(automation_rule, account, conversation)
      end

      it 'does not call AutomationRules::ActionService if conditions do not match' do
        allow(condition_match).to receive(:present?).and_return(false)
        listener.message_created(event)
        expect(AutomationRules::ActionService).not_to have_received(:new).with(automation_rule, account, conversation)
      end

      it 'calls AutomationRules::ActionService for each rule when multiple rules are present' do
        create(:automation_rule, event_name: 'message_created', account: account)
        allow(condition_match).to receive(:present?).and_return(true)
        listener.message_created(event)
        expect(AutomationRules::ActionService).to have_received(:new).twice
      end

      it 'does not call AutomationRules::ActionService if performed by automation' do
        event.data[:performed_by] = automation_rule
        allow(condition_match).to receive(:present?).and_return(true)
        listener.message_created(event)
        expect(AutomationRules::ActionService).not_to have_received(:new).with(automation_rule, account, conversation)
      end

      it 'does not call AutomationRules::ActionService if message is activity message' do
        message.update!(message_type: 'activity')
        allow(condition_match).to receive(:present?).and_return(true)
        listener.message_created(event)
        expect(AutomationRules::ActionService).not_to have_received(:new).with(automation_rule, account, conversation)
      end

      it 'does not call AutomationRules::ActionService if message is auto reply email' do
        email_channel = create(:channel_email, account: account)
        email_inbox = create(:inbox, channel: email_channel, account: account)
        email_conversation = create(:conversation, inbox: email_inbox, account: account)
        email_message = create(:message, conversation: email_conversation, account: account, content_attributes: { email: { auto_reply: true } })
        email_event = Events::Base.new('message_created', Time.zone.now, { message: email_message })
        allow(condition_match).to receive(:present?).and_return(true)

        listener.message_created(email_event)
        expect(AutomationRules::ActionService).not_to have_received(:new)
      end

      it 'calls AutomationRules::ActionService if message is a private note' do
        message.update!(private: true)
        allow(condition_match).to receive(:present?).and_return(true)

        listener.message_created(event)

        expect(AutomationRules::ActionService).to have_received(:new).with(automation_rule, account, conversation)
      end

      it 'does not call AutomationRules::ActionService if conditions do not match based on content' do
        message.update!(processed_message_content: 'hi', content: "hi\n\nhello")
        allow(condition_match).to receive(:present?).and_return(false)
        listener.message_created(event)
        expect(AutomationRules::ActionService).not_to have_received(:new).with(automation_rule, account, conversation)
      end

      it 'passes conversation attributes to conditions filter service' do
        conversation.update!(status: :open, priority: :high)
        listener.message_created(event)
        expect(AutomationRules::ConditionsFilterService).to have_received(:new).with(
          automation_rule,
          conversation,
          { message: message, changed_attributes: { content: %w[nil Hi] } }
        )
      end
    end
  end

  describe 'delayed rules' do
    let!(:automation_rule) { create(:automation_rule, event_name: 'conversation_updated', account: account, execution_delay: 60) }
    let(:event) do
      Events::Base.new('conversation_updated', Time.zone.now, { conversation: conversation, changed_attributes: {} })
    end

    before { allow(condition_match).to receive(:present?).and_return(true) }

    context 'when the delayed_automations feature is enabled' do
      before { account.enable_features!('delayed_automations') }

      it 'records a pending execution instead of running actions' do
        expect { listener.conversation_updated(event) }.to change(AutomationRulePendingExecution, :count).by(1)
        expect(AutomationRules::ActionService).not_to have_received(:new)
        expect(AutomationRulePendingExecution.last.due_at).to be_within(5.seconds).of(60.minutes.from_now)
      end

      it 'still runs rules without a delay immediately' do
        automation_rule.update!(execution_delay: nil)

        expect { listener.conversation_updated(event) }.not_to change(AutomationRulePendingExecution, :count)
        expect(AutomationRules::ActionService).to have_received(:new).with(automation_rule, account, conversation)
      end
    end

    context 'when the delayed_automations feature is disabled' do
      it 'neither arms a pending execution nor falls back to immediate execution' do
        expect { listener.conversation_updated(event) }.not_to change(AutomationRulePendingExecution, :count)
        expect(AutomationRules::ActionService).not_to have_received(:new)
      end
    end
  end

  # An inactivity wait is a conversation rule, and a message dispatches no conversation event, so
  # the message path has to arm it as well or a conversation that only exchanges messages would
  # never restart its count.
  describe 'the inactivity trigger' do
    let(:automation_rule) do
      create(:automation_rule, account: account, event_name: 'conversation_updated', execution_delay: 60,
                               execution_delay_trigger: 'inactivity',
                               conditions: [{ 'attribute_key' => 'inbox_id', 'filter_operator' => 'equal_to',
                                              'values' => [conversation.inbox_id], 'query_operator' => nil }],
                               actions: [{ 'action_name' => 'remove_assigned_agent', 'action_params' => [] }])
    end

    before do
      allow(AutomationRules::ConditionsFilterService).to receive(:new).and_call_original
      account.enable_features!('delayed_automations')
      automation_rule
    end

    it 'arms the wait on a message, with one row for the conversation and no message on it' do
      message = create(:message, account: account, conversation: conversation, message_type: :incoming)
      event = Events::Base.new('message_created', Time.zone.now, { message: message })

      expect { listener.message_created(event) }.to change(AutomationRulePendingExecution, :count).by(1)
      row = AutomationRulePendingExecution.last
      expect(row.automation_rule).to eq(automation_rule)
      expect(row.episode_key).to eq('inactivity')
      expect(row.message_id).to be_nil
    end

    it 'restarts the count on the next message instead of arming a second row' do
      first = create(:message, account: account, conversation: conversation, message_type: :incoming)
      listener.message_created(Events::Base.new('message_created', Time.zone.now, { message: first }))
      armed_due_at = AutomationRulePendingExecution.last.due_at

      travel_to(30.minutes.from_now) do
        later = create(:message, account: account, conversation: conversation, message_type: :outgoing)
        event = Events::Base.new('message_created', Time.zone.now, { message: later })

        expect { listener.message_created(event) }.not_to change(AutomationRulePendingExecution, :count)
        expect(AutomationRulePendingExecution.last.due_at).to be > armed_due_at
      end
    end

    # An edit moves no conversation timestamp at all, so without this the wait would fire on a
    # conversation somebody was writing in.
    it 'restarts the count when a message is edited' do
      message = create(:message, account: account, conversation: conversation, message_type: :outgoing)
      listener.message_created(Events::Base.new('message_created', Time.zone.now, { message: message }))
      armed_due_at = AutomationRulePendingExecution.last.due_at

      travel_to(30.minutes.from_now) do
        message.update!(content: 'corrigindo o que eu disse')
        event = Events::Base.new('message_edited', Time.zone.now, { message: message, content: message.content })

        expect { listener.message_edited(event) }.not_to change(AutomationRulePendingExecution, :count)
        expect(AutomationRulePendingExecution.last.due_at).to be > armed_due_at
      end
    end

    # The message run claims key an edit on its body, so an edit that restores a body the rule
    # already saw would reuse that finished claim. An arm is not a run: it writes a clock, and
    # writing the same clock twice writes the same clock.
    it 'restarts the count on an edit that restores a body the rule already saw' do
      message = create(:message, account: account, conversation: conversation, message_type: :outgoing, content: 'A')
      listener.message_created(Events::Base.new('message_created', Time.zone.now, { message: message }))

      travel_to(10.minutes.from_now) do
        message.update!(content: 'B')
        listener.message_edited(Events::Base.new('message_edited', Time.zone.now, { message: message, content: 'B' }))
        message.update!(content: 'A')
        listener.message_edited(Events::Base.new('message_edited', Time.zone.now, { message: message, content: 'A' }))
      end

      restored_at = nil
      travel_to(20.minutes.from_now) do
        message.update!(content: 'B')
        listener.message_edited(Events::Base.new('message_edited', Time.zone.now, { message: message, content: 'B' }))
        restored_at = Time.current
      end

      expect(AutomationRulePendingExecution.last.due_at).to be_within(5.seconds).of(restored_at + 60.minutes)
    end

    # What another rule wrote is activity on the conversation, and the fire-time clock has always
    # read it that way. A row that already ran is terminal and nothing sweeps it again, so an arm
    # that disagreed would leave that activity unable to ever start a new count.
    it 'restarts a finished count on a message another rule sent' do
      first = create(:message, account: account, conversation: conversation, message_type: :incoming)
      listener.message_created(Events::Base.new('message_created', Time.zone.now, { message: first }))
      row = AutomationRulePendingExecution.last
      row.update!(status: :executed)

      travel_to(30.minutes.from_now) do
        other_rule = create(:automation_rule, account: account, event_name: 'message_created')
        reply = create(:message, account: account, conversation: conversation, message_type: :outgoing)
        event = Events::Base.new('message_created', Time.zone.now, { message: reply, performed_by: other_rule })

        listener.message_created(event)

        expect(row.reload).to be_pending
        expect(row.due_at).to be_within(5.seconds).of(60.minutes.from_now)
      end
    end

    # A rule that speaks because a conversation went quiet is not that conversation coming alive.
    # Reading it that way is how two waits on silence end up answering each other for ever.
    it 'does not restart a finished count on a message another wait on silence sent' do
      first = create(:message, account: account, conversation: conversation, message_type: :incoming)
      listener.message_created(Events::Base.new('message_created', Time.zone.now, { message: first }))
      row = AutomationRulePendingExecution.last
      row.update!(status: :executed)

      travel_to(30.minutes.from_now) do
        other_wait = create(:automation_rule, account: account, event_name: 'conversation_updated',
                                              execution_delay: 60, execution_delay_trigger: 'inactivity')
        reply = create(:message, account: account, conversation: conversation, message_type: :outgoing)
        event = Events::Base.new('message_created', Time.zone.now, { message: reply, performed_by: other_wait })

        listener.message_created(event)

        expect(row.reload).to be_executed
      end
    end

    # The columns hold microseconds and an event's timestamp keeps its nanoseconds through the
    # queue, so the same event replayed reads as newer than the row it armed itself.
    it 'does not read a replay of the same event as new activity' do
      first = create(:message, account: account, conversation: conversation, message_type: :incoming)
      happened_at = Time.zone.now.change(nsec: 123_456_789)
      listener.message_created(Events::Base.new('message_created', happened_at, { message: first }))
      row = AutomationRulePendingExecution.last
      row.update!(status: :executed)

      listener.message_created(Events::Base.new('message_created', happened_at, { message: first }))

      expect(row.reload).to be_executed
    end

    # A message's updated_at moves for things that are not activity at all -- a delivery receipt,
    # a status update -- so a retry of the same event would arm from a timestamp the event never
    # had. The performed_by guard cannot see it either: a retry keeps the original actor.
    it 'arms a message event from when it happened, not from a timestamp the message got later' do
      first = create(:message, account: account, conversation: conversation, message_type: :incoming)
      happened_at = Time.zone.now
      listener.message_created(Events::Base.new('message_created', happened_at, { message: first }))
      row = AutomationRulePendingExecution.last
      row.update!(status: :executed)

      travel_to(30.minutes.from_now) do
        first.update!(status: :delivered)
        listener.message_created(Events::Base.new('message_created', happened_at, { message: first.reload }))

        expect(row.reload).to be_executed
      end
    end

    # This job can run long after its event, and the conversation it deserializes is the one the
    # rule's own actions have since written to. Arming from that state is the rule re-arming itself
    # from its own note, and the performed_by guard cannot see it: the retry keeps the original actor.
    it 'arms from when the event happened, not from the conversation as a retry finds it' do
      first = create(:message, account: account, conversation: conversation, message_type: :incoming)
      listener.message_created(Events::Base.new('message_created', Time.zone.now, { message: first }))
      row = AutomationRulePendingExecution.last
      row.update!(status: :executed)
      happened_at = first.updated_at

      travel_to(30.minutes.from_now) do
        conversation.update!(last_activity_at: Time.current)
        retried = Events::Base.new('conversation_updated', happened_at, { conversation: conversation.reload })

        listener.conversation_updated(retried)

        expect(row.reload).to be_executed
      end
    end

    # A rule's own writing is no reason to run the rules again, but it is activity, and a wait that
    # already ran is terminal: no sweep will read it, so the arm is the only thing that can.
    it 'restarts a finished count on a conversation change another rule made' do
      first = create(:message, account: account, conversation: conversation, message_type: :incoming)
      listener.message_created(Events::Base.new('message_created', Time.zone.now, { message: first }))
      row = AutomationRulePendingExecution.last
      row.update!(status: :executed)

      travel_to(30.minutes.from_now) do
        other_rule = create(:automation_rule, account: account, event_name: 'conversation_updated')
        conversation.update!(custom_attributes: { 'fechamento' => 'Em negociação' })
        event = Events::Base.new('conversation_updated', Time.zone.now,
                                 { conversation: conversation.reload, performed_by: other_rule })

        listener.conversation_updated(event)

        expect(row.reload).to be_pending
        expect(row.due_at).to be_within(5.seconds).of(60.minutes.from_now)
      end
    end

    # The rule's own actions change the conversation -- it reopens it, it strips an attribute -- and
    # each of those dispatches an update. Arming from them would be the rule resurrecting itself the
    # moment it finished, for ever.
    it 'does not restart its own count from the conversation changes its actions made' do
      first = create(:message, account: account, conversation: conversation, message_type: :incoming)
      listener.message_created(Events::Base.new('message_created', Time.zone.now, { message: first }))
      row = AutomationRulePendingExecution.last
      row.update!(status: :executed)

      travel_to(30.minutes.from_now) do
        conversation.update!(custom_attributes: {})
        event = Events::Base.new('conversation_updated', Time.zone.now,
                                 { conversation: conversation.reload, performed_by: automation_rule })

        listener.conversation_updated(event)

        expect(row.reload).to be_executed
      end
    end

    it 'ignores a message the automation itself sent, so its own note does not restart the count' do
      message = create(:message, account: account, conversation: conversation, message_type: :outgoing)
      event = Events::Base.new('message_created', Time.zone.now, { message: message, performed_by: automation_rule })

      expect { listener.message_created(event) }.not_to change(AutomationRulePendingExecution, :count)
    end
  end

  # The builder's "customer unresponsive" trigger writes message_type = outgoing plus
  # private_note = false. A pending status condition can be joined to those structural conditions
  # so the follow-up only arms while the conversation is pending.
  describe 'the curated customer-unresponsive trigger' do
    let(:automation_rule) do
      create(:automation_rule, account: account, event_name: 'message_created', execution_delay: 60,
                               conditions: [
                                 { 'attribute_key' => 'message_type', 'filter_operator' => 'equal_to',
                                   'values' => ['outgoing'], 'query_operator' => 'and' },
                                 { 'attribute_key' => 'private_note', 'filter_operator' => 'equal_to',
                                   'values' => [false], 'query_operator' => 'and' },
                                 { 'attribute_key' => 'inbox_id', 'filter_operator' => 'equal_to',
                                   'values' => [conversation.inbox_id], 'query_operator' => 'and' },
                                 { 'attribute_key' => 'status', 'filter_operator' => 'equal_to',
                                   'values' => ['pending'], 'query_operator' => nil }
                               ],
                               actions: [{ 'action_name' => 'add_label', 'action_params' => ['stale'] }])
    end

    before do
      allow(AutomationRules::ConditionsFilterService).to receive(:new).and_call_original
      account.enable_features!('delayed_automations')
      automation_rule
    end

    it 'arms the wait on a real agent reply' do
      conversation.pending!
      reply = create(:message, account: account, conversation: conversation, message_type: :outgoing)
      event = Events::Base.new('message_created', Time.zone.now, { message: reply })

      expect { listener.message_created(event) }.to change(AutomationRulePendingExecution, :count).by(1)
      expect(AutomationRulePendingExecution.last.automation_rule).to eq(automation_rule)
    end

    it 'does not arm the wait on a private note' do
      conversation.pending!
      note = create(:message, account: account, conversation: conversation, message_type: :outgoing, private: true)
      event = Events::Base.new('message_created', Time.zone.now, { message: note })

      expect { listener.message_created(event) }.not_to change(AutomationRulePendingExecution, :count)
    end

    it 'does not arm the wait when the conversation is not pending' do
      conversation.open!
      reply = create(:message, account: account, conversation: conversation, message_type: :outgoing)
      event = Events::Base.new('message_created', Time.zone.now, { message: reply })

      expect { listener.message_created(event) }.not_to change(AutomationRulePendingExecution, :count)
    end
  end
end
