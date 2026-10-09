require 'rails_helper'

RSpec.describe Conversations::UnreadCounts::FilterQueryCounter do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }

  before { create(:inbox_member, user: agent, inbox: inbox) }

  describe '#base_relation' do
    it 'applies the planner hint to permission scoping only for label filters' do
      label_query = { payload: [{ attribute_key: 'labels', filter_operator: 'equal_to', values: ['support'], query_operator: nil }] }
      status_query = { payload: [{ attribute_key: 'status', filter_operator: 'equal_to', values: ['open'], query_operator: nil }] }

      expect(described_class.new(account: account, user: agent, query: label_query).base_relation.to_sql)
        .to include('conversations.inbox_id + 0')
      expect(described_class.new(account: account, user: agent, query: status_query).base_relation.to_sql)
        .not_to include('inbox_id + 0')
    end
  end

  describe '#perform' do
    it 'counts conversations when a text custom attribute filter uses a numeric JSON value' do
      create(:custom_attribute_definition,
             attribute_key: 'ticket_reference',
             account: account,
             attribute_model: 'conversation_attribute',
             attribute_display_type: 'text')
      conversation = create(:conversation, account: account, inbox: inbox, custom_attributes: { ticket_reference: '12345' })
      create(:message, account: account, conversation: conversation, inbox: inbox, message_type: :incoming)

      query = { payload: [{ attribute_key: 'ticket_reference', filter_operator: 'equal_to', values: [12_345], query_operator: nil }] }

      expect(described_class.new(account: account, user: agent, query: query).perform).to eq(1)
    end
  end
end
