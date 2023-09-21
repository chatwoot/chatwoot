require 'rails_helper'

RSpec.describe AutomationRules::ConditionsFilterService do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:email_channel) { create(:channel_email, account: account) }
  let(:email_inbox) { create(:inbox, channel: email_channel, account: account) }
  let(:message) do
    create(:message, account: account, conversation: conversation, content: 'test text', inbox: conversation.inbox, message_type: :incoming)
  end
  let(:rule) { create(:automation_rule, account: account) }

  before do
    conversation = create(:conversation, account: account)
    conversation.contact.update(phone_number: '+918484828282', email: 'test@test.com')
    create(:conversation, account: account)
    create(:conversation, account: account)
  end

  describe '#perform' do
    context 'when conditions based on filter_operator equal_to' do
      before do
        rule.conditions = [{ 'values': ['open'], 'attribute_key': 'status', 'query_operator': nil, 'filter_operator': 'equal_to' }]
        rule.save
      end

      context 'when conditions in rule matches with object' do
        it 'will return true' do
          expect(described_class.new(rule, conversation, { changed_attributes: { status: [nil, 'open'] } }).perform).to be(true)
        end
      end

      context 'when conditions in rule does not match with object' do
        it 'will return false' do
          conversation.update(status: 'resolved')
          expect(described_class.new(rule, conversation, { changed_attributes: { status: %w[open resolved] } }).perform).to be(false)
        end
      end
    end

    context 'when conditions based on filter_operator start_with' do
      before do
        contact = conversation.contact
        contact.update(phone_number: '+918484848484')
        rule.conditions = [
          { 'values': ['+918484'], 'attribute_key': 'phone_number', 'query_operator': 'OR', 'filter_operator': 'starts_with' },
          { 'values': ['test'], 'attribute_key': 'email', 'query_operator': nil, 'filter_operator': 'contains' }
        ]
        rule.save
      end

      context 'when conditions in rule matches with object' do
        it 'will return true' do
          expect(described_class.new(rule, conversation, { changed_attributes: {} }).perform).to be(true)
        end
      end

      context 'when conditions in rule does not match with object' do
        it 'will return false' do
          conversation.contact.update(phone_number: '+918585858585')
          expect(described_class.new(rule, conversation, { changed_attributes: {} }).perform).to be(false)
        end
      end
    end

    context 'when conditions based on messages attributes' do
      context 'when filter_operator is equal_to' do
        before do
          rule.conditions = [
            { 'values': ['test text'], 'attribute_key': 'content', 'query_operator': 'AND', 'filter_operator': 'equal_to' },
            { 'values': ['incoming'], 'attribute_key': 'message_type', 'query_operator': nil, 'filter_operator': 'equal_to' }
          ]
          rule.save
        end

        it 'will return true when conditions matches' do
          expect(described_class.new(rule, conversation, { message: message, changed_attributes: {} }).perform).to be(true)
        end

        it 'will return false when conditions in rule does not match' do
          message.update!(message_type: :outgoing)
          expect(described_class.new(rule, conversation, { message: message, changed_attributes: {} }).perform).to be(false)
        end
      end

      context 'when filter_operator is on processed_message_content' do
        before do
          rule.conditions = [
            { 'values': ['help'], 'attribute_key': 'content', 'query_operator': 'AND', 'filter_operator': 'contains' },
            { 'values': ['incoming'], 'attribute_key': 'message_type', 'query_operator': nil, 'filter_operator': 'equal_to' }
          ]
          rule.save
        end

        let(:conversation) { create(:conversation, account: account, inbox: email_inbox) }
        let(:message) do
          create(:message, account: account, conversation: conversation, content: "We will help you\n\n\n test",
                           inbox: conversation.inbox, message_type: :incoming,
                           content_attributes: { email: { text_content: { quoted: 'We will help you' } } })
        end

        it 'will return true for processed_message_content matches' do
          message
          expect(described_class.new(rule, conversation, { message: message, changed_attributes: {} }).perform).to be(true)
        end

        it 'will return false when processed_message_content does no match' do
          rule.update(conditions: [{ 'values': ['text'], 'attribute_key': 'content', 'query_operator': nil, 'filter_operator': 'contains' }])

          expect(described_class.new(rule, conversation, { message: message, changed_attributes: {} }).perform).to be(false)
        end
      end
    end
  end
end
