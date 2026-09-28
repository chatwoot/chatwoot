require 'rails_helper'

RSpec.describe ConversationMonitors::ProcessAutomationDeliveryJob do
  let(:account) { create(:account) }
  let(:monitor) { create(:conversation_monitor, account: account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:rule) do
    create(:automation_rule, account: account, event_name: 'monitor_matched', monitor: monitor,
                             conditions: [], actions: [{ action_name: 'add_label', action_params: ['refund'] }])
  end
  let(:delivery) do
    ConversationMonitors::AutomationDelivery.create!(account: account, monitor: monitor, automation_rule: rule,
                                                     conversation: conversation)
  end

  before { account.enable_features!('automations', 'reports', 'conversation_monitors') }

  it 'runs the linked automation action for a claimed match' do
    create(:label, account: account, title: 'refund')

    described_class.perform_now(delivery.id)

    expect(conversation.reload.label_list).to include('refund')
    expect(delivery.reload.status).to eq('executed')
  end

  it 'executes once even when the delivery job is enqueued twice' do
    action_service = instance_double(AutomationRules::ActionService, perform: nil)
    allow(AutomationRules::ActionService).to receive(:new).and_return(action_service)

    described_class.perform_now(delivery.id)
    described_class.perform_now(delivery.id)

    expect(action_service).to have_received(:perform).once
    expect(delivery.reload.status).to eq('executed')
  end

  it 'skips a queued action when the monitor is paused' do
    delivery
    monitor.with_lock do
      monitor.update!(paused_at: Time.current)
      monitor.disable_automations!
    end

    expect { described_class.perform_now(delivery.id) }.not_to(change { conversation.reload.labels.count })
    expect(delivery.reload.status).to eq('skipped')
    expect(rule.reload.active).to be(false)
  end

  it 'skips a queued action when the monitor entitlement is disabled' do
    delivery
    account.disable_features!('conversation_monitors')

    described_class.perform_now(delivery.id)

    expect(delivery.reload).to have_attributes(status: 'skipped', skip_reason: 'monitor_or_rule_unavailable')
  end
end
