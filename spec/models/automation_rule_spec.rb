require 'rails_helper'
require Rails.root.join 'spec/models/concerns/reauthorizable_shared.rb'

RSpec.describe AutomationRule do
  describe 'concerns' do
    it_behaves_like 'reauthorizable'
  end

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

    it 'allows labels as a valid condition attribute' do
      params[:conditions] = [
        {
          attribute_key: 'labels',
          filter_operator: 'equal_to',
          values: ['bug'],
          query_operator: nil
        }
      ]
      rule = FactoryBot.build(:automation_rule, params)
      expect(rule.valid?).to be true
    end

    it 'validates label condition operators' do
      params[:conditions] = [
        {
          attribute_key: 'labels',
          filter_operator: 'is_present',
          values: [],
          query_operator: nil
        }
      ]
      rule = FactoryBot.build(:automation_rule, params)
      expect(rule.valid?).to be true
    end
  end

  describe 'reauthorizable' do
    context 'when prompt_reauthorization!' do
      it 'marks the rule inactive' do
        rule = create(:automation_rule)
        expect(rule.active).to be true
        rule.prompt_reauthorization!
        expect(rule.active).to be false
      end
    end

    context 'when reauthorization_required?' do
      it 'unsets the error count if conditions are updated' do
        rule = create(:automation_rule)
        rule.prompt_reauthorization!
        expect(rule.reauthorization_required?).to be true

        rule.update!(conditions: [{ attribute_key: 'browser_language', filter_operator: 'equal_to', values: ['en'], query_operator: 'AND' }])
        expect(rule.reauthorization_required?).to be false
      end

      it 'will not unset the error count if conditions are not updated' do
        rule = create(:automation_rule)
        rule.prompt_reauthorization!
        expect(rule.reauthorization_required?).to be true

        rule.update!(name: 'Updated name')
        expect(rule.reauthorization_required?).to be true
      end
    end
  end

  describe 'create_scheduled_message action validation' do
    let(:account) { create(:account) }

    def build_rule_with_scheduled_message(action_params)
      FactoryBot.build(:automation_rule,
                       account: account,
                       event_name: 'conversation_created',
                       conditions: [{ attribute_key: 'status', filter_operator: 'equal_to', values: ['open'], query_operator: nil }],
                       actions: [{ action_name: 'create_scheduled_message', action_params: [action_params] }])
    end

    it 'is valid with content and valid delay' do
      rule = build_rule_with_scheduled_message({ 'content' => 'Hello', 'delay_minutes' => 60 })
      expect(rule).to be_valid
    end

    it 'is valid with template_params and valid delay' do
      rule = build_rule_with_scheduled_message({ 'template_params' => { 'name' => 'test' }, 'delay_minutes' => 60 })
      expect(rule).to be_valid
    end

    it 'is invalid when delay_minutes is below minimum' do
      rule = build_rule_with_scheduled_message({ 'content' => 'Hello', 'delay_minutes' => 0 })
      expect(rule).not_to be_valid
      expect(rule.errors[:actions]).to be_present
    end

    it 'is invalid when delay_minutes exceeds maximum' do
      rule = build_rule_with_scheduled_message({ 'content' => 'Hello', 'delay_minutes' => described_class::MAX_SCHEDULED_MESSAGE_DELAY_MINUTES + 1 })
      expect(rule).not_to be_valid
      expect(rule.errors[:actions]).to be_present
    end

    it 'is valid at maximum delay boundary' do
      rule = build_rule_with_scheduled_message({ 'content' => 'Hello', 'delay_minutes' => described_class::MAX_SCHEDULED_MESSAGE_DELAY_MINUTES })
      expect(rule).to be_valid
    end

    it 'is valid at minimum delay boundary' do
      rule = build_rule_with_scheduled_message({ 'content' => 'Hello', 'delay_minutes' => 1 })
      expect(rule).to be_valid
    end

    it 'is invalid without content, attachment, or template_params' do
      rule = build_rule_with_scheduled_message({ 'delay_minutes' => 60 })
      expect(rule).not_to be_valid
      expect(rule.errors[:actions]).to be_present
    end
  end
end
