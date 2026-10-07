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
