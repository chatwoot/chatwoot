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
  end

  describe 'send_whatsapp_template action validation' do
    let(:account) { create(:account) }
    let(:whatsapp_inbox) { create(:channel_whatsapp, account: account, sync_templates: false, validate_provider_config: false).inbox }
    let(:other_whatsapp_inbox) do
      create(:channel_whatsapp, account: account, sync_templates: false, validate_provider_config: false).inbox
    end
    let(:web_inbox) { create(:inbox, account: account) }

    def build_rule(action_params)
      build(:automation_rule,
            account: account,
            event_name: 'conversation_created',
            conditions: [{ attribute_key: 'status', filter_operator: 'equal_to', values: ['open'], query_operator: nil }],
            actions: [{ action_name: 'send_whatsapp_template', action_params: action_params }])
    end

    it 'is valid with one or more WhatsApp inboxes and a template_name' do
      rule = build_rule([{
                          inbox_ids: [whatsapp_inbox.id, other_whatsapp_inbox.id],
                          template_name: 'sample_shipping_confirmation',
                          template_language: 'en_US',
                          processed_params: { '1' => '{{contact.name}}' }
                        }])
      expect(rule).to be_valid
    end

    it 'is invalid when no inboxes are configured' do
      rule = build_rule([{ inbox_ids: [], template_name: 'sample_shipping_confirmation' }])
      expect(rule).to be_invalid
      expect(rule.errors[:actions].join).to include('requires at least one WhatsApp inbox')
    end

    it 'is invalid when a non-WhatsApp inbox is configured' do
      rule = build_rule([{ inbox_ids: [web_inbox.id], template_name: 'sample_shipping_confirmation' }])
      expect(rule).to be_invalid
      expect(rule.errors[:actions].join).to include('are not WhatsApp inboxes')
    end

    it 'is invalid when template_name is missing' do
      rule = build_rule([{ inbox_ids: [whatsapp_inbox.id] }])
      expect(rule).to be_invalid
      expect(rule.errors[:actions].join).to include('requires a template_name')
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
end
