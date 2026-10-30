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
    it 'counts unread conversations that match a participant filter' do
      participating_conversation = create(:conversation, account: account, inbox: inbox)
      other_conversation = create(:conversation, account: account, inbox: inbox)
      [participating_conversation, other_conversation].each do |conversation|
        create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming)
      end
      create(:conversation_participant, account: account, conversation: participating_conversation, user: agent)
      query = { payload: [{ attribute_key: 'participant_id', filter_operator: 'equal_to', values: [agent.id], query_operator: nil }] }

      expect(described_class.new(account: account, user: agent, query: query).perform).to eq 1
    end
  end
end
