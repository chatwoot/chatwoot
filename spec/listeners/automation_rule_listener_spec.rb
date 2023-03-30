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
    end
  end
end
