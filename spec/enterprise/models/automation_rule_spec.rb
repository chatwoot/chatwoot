# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AutomationRule do
  let!(:automation_rule) { create(:automation_rule, name: 'automation rule 1') }

  describe 'audit log' do
    context 'when automation rule is created' do
      it 'has associated audit log created' do
        expect(Audited::Audit.where(auditable_type: 'AutomationRule', action: 'create').count).to eq 1
      end
    end

    context 'when automation rule is updated' do
      it 'has associated audit log created' do
        automation_rule.update(name: 'automation rule 2')
        expect(Audited::Audit.where(auditable_type: 'AutomationRule', action: 'update').count).to eq 1
      end
    end

    context 'when automation rule is deleted' do
      it 'has associated audit log created' do
        automation_rule.destroy!
        expect(Audited::Audit.where(auditable_type: 'AutomationRule', action: 'destroy').count).to eq 1
      end
    end

    context 'when automation rule is in enterprise namespace' do
      it 'has associated sla methods available' do
        expect(automation_rule.conditions_attributes).to include('sla_policy_id')
        expect(automation_rule.actions_attributes).to include('add_sla')
      end
    end
  end

  describe 'monitor matched event' do
    let(:account) { create(:account) }
    let(:monitor) { create(:conversation_monitor, account: account) }

    before { account.enable_features!('automations', 'reports', 'conversation_monitors') }

    it 'stores the monitor source and activation boundary' do
      rule = create(:automation_rule, account: account, event_name: 'monitor_matched', monitor: monitor, conditions: [])

      expect(rule.monitor_event_activated_at).to be_present
      expect(rule.monitor_availability).to eq('available')
    end

    it 'rejects a paused or cross-account monitor and delayed execution' do
      other_monitor = create(:conversation_monitor)
      rule = build(:automation_rule, account: account, event_name: 'monitor_matched', monitor: other_monitor)
      expect(rule).not_to be_valid

      monitor.update!(paused_at: Time.current)
      rule.monitor = monitor
      expect(rule).not_to be_valid

      monitor.update!(paused_at: nil)
      rule.execution_delay = 10
      expect(rule).not_to be_valid
    end

    it 'reports an unavailable source when either monitor entitlement is disabled' do
      rule = create(:automation_rule, account: account, event_name: 'monitor_matched', monitor: monitor, conditions: [])

      account.disable_features!('reports')
      expect(rule.reload.monitor_availability).to eq('unavailable')

      account.enable_features!('reports')
      account.disable_features!('automations')
      expect(rule.reload.monitor_availability).to eq('unavailable')
    end

    it 'removes queued monitor deliveries when the linked rule is destroyed' do
      rule = create(:automation_rule, account: account, event_name: 'monitor_matched', monitor: monitor, conditions: [])
      conversation = create(:conversation, account: account)
      delivery = ConversationMonitors::AutomationDelivery.create!(account: account, monitor: monitor,
                                                                  automation_rule: rule, conversation: conversation)

      rule.destroy!

      expect(ConversationMonitors::AutomationDelivery).not_to exist(id: delivery.id)
    end
  end
end
