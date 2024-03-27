require 'rails_helper'

RSpec.describe AutomationRule do
  describe 'associations' do
    let(:account) { create(:account) }
    let(:params) do
      {
        name: 'Notify Conversation Created and mark priority query',
        description: 'Notify all administrator about conversation created and mark priority query',
        event_name: 'conversation_created',
        account_id: account.id,
        conditions: [
          {
            attribute_key: 'browser_language',
            filter_operator: 'equal_to',
            values: ['en'],
            query_operator: 'AND'
          },
          {
            attribute_key: 'country_code',
            filter_operator: 'equal_to',
            values: %w[USA UK],
            query_operator: nil
          }
        ],
        actions: [
          {
            action_name: :send_message,
            action_params: ['Welcome to the chatwoot platform.']
          },
          {
            action_name: :assign_team,
            action_params: [1]
          },
          {
            action_name: :add_label,
            action_params: %w[support priority_customer]
          },
          {
            action_name: :assign_agent,
            action_params: [1]
          }
        ]
      }.with_indifferent_access
    end

    it 'returns valid record' do
      rule = FactoryBot.build(:automation_rule, params)
      expect(rule.valid?).to be true
    end

    it 'returns invalid record' do
      params[:conditions][0].delete('query_operator')
      rule = FactoryBot.build(:automation_rule, params)
      expect(rule.valid?).to be false
      expect(rule.errors.messages[:conditions]).to eq(['Automation conditions should have query operator.'])
    end
  end

  describe '#disable_rule_and_notify' do
    let(:account) { create(:account) }
    let(:automation_rule) { create(:automation_rule, account: account) }

    it 'disables the automation rule' do
      automation_rule.disable_rule_and_notify
      expect(automation_rule.reload.active).to be false
    end

    it 'sends a notification email' do
      mailer = double
      mailer_action = double
      allow(AdministratorNotifications::ChannelNotificationsMailer).to receive(:with).with(account: account).and_return(mailer)
      allow(mailer).to receive(:automation_rule_disabled).and_return(mailer_action)
      allow(mailer_action).to receive(:deliver_later)

      automation_rule.disable_rule_and_notify

      expect(mailer).to have_received(:automation_rule_disabled).with(automation_rule)
      expect(mailer_action).to have_received(:deliver_later)
    end
  end

  describe '#error_counts' do
    let(:account) { create(:account) }
    let(:automation_rule) { create(:automation_rule, account: account, active: true) }

    it 'increments the error count' do
      automation_rule.invalid_condition_error!
      expect(automation_rule.send(:authorization_error_count)).to eq(1)
    end

    it 'disables the automation rule if error count exceeds threshold' do
      allow(automation_rule).to receive(:authorization_error_count).and_return(3)
      automation_rule.invalid_condition_error!
      expect(automation_rule.active).to be false
    end

    it 'resets the error count if the rule is updated' do
      automation_rule.invalid_condition_error!
      expect(automation_rule.send(:authorization_error_count)).to eq(1)
      automation_rule.update(name: 'New Name')
      expect(automation_rule.send(:authorization_error_count)).to eq(0)
    end
  end
end
