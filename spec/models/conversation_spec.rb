# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Conversation, type: :model do
  describe '#update_assignee' do
    subject(:update_assignee) { conversation.update_assignee(agent) }

    let(:conversation) { create(:complete_conversation, assignee: nil) }
    let(:agent) do
      create(:user, email: 'agent@example.com', account: conversation.account, role: :agent)
    end

    it 'assigns the agent to conversation' do
      expect(update_assignee).to eq(true)
      expect(conversation.reload.assignee).to eq(agent)
    end
  end

  describe '#toggle_status' do
    subject(:toggle_status) { conversation.toggle_status }

    let(:conversation) { create(:complete_conversation, status: :open) }

    it 'toggles conversation status' do
      expect(toggle_status).to eq(true)
      expect(conversation.reload.status).to eq('resolved')
    end
  end

  describe '#lock!' do
    subject(:lock!) { conversation.lock! }

    let(:conversation) { create(:complete_conversation) }

    it 'assigns locks the conversation' do
      expect(lock!).to eq(true)
      expect(conversation.reload.locked).to eq(true)
    end
  end

  describe '#unlock!' do
    subject(:unlock!) { conversation.unlock! }

    let(:conversation) { create(:complete_conversation) }

    it 'unlocks the conversation' do
      expect(unlock!).to eq(true)
      expect(conversation.reload.locked).to eq(false)
    end
  end

  describe 'unread_messages' do
    subject(:unread_messages) { conversation.unread_messages }

    let(:conversation) { create(:complete_conversation, agent_last_seen_at: 1.hour.ago) }
    let(:message_params) do
      {
        conversation: conversation,
        account: conversation.account,
        inbox: conversation.inbox,
        user: conversation.assignee
      }
    end
    let!(:message) do
      create(:message, created_at: 1.minute.ago, **message_params)
    end

    before do
      create(:message, created_at: 1.month.ago, **message_params)
    end

    it 'returns unread messages' do
      expect(unread_messages).to contain_exactly(message)
    end
  end

  describe 'unread_incoming_messages' do
    subject(:unread_incoming_messages) { conversation.unread_incoming_messages }

    let(:conversation) { create(:complete_conversation, agent_last_seen_at: 1.hour.ago) }
    let(:message_params) do
      {
        conversation: conversation,
        account: conversation.account,
        inbox: conversation.inbox,
        user: conversation.assignee,
        created_at: 1.minute.ago
      }
    end
    let!(:message) do
      create(:message, message_type: :incoming, **message_params)
    end

    before do
      create(:message, message_type: :outgoing, **message_params)
    end

    it 'returns unread incoming messages' do
      expect(unread_incoming_messages).to contain_exactly(message)
    end
  end

  describe '#push_event_data' do
    subject(:push_event_data) { conversation.push_event_data }

    let(:conversation) { create(:complete_conversation) }
    let(:expected_data) do
      {
        meta: {
          sender: conversation.sender.push_event_data,
          assignee: conversation.assignee
        },
        id: conversation.display_id,
        messages: [nil],
        inbox_id: conversation.inbox_id,
        status: conversation.status_before_type_cast.to_i,
        timestamp: conversation.created_at.to_i,
        user_last_seen_at: conversation.user_last_seen_at.to_i,
        agent_last_seen_at: conversation.agent_last_seen_at.to_i,
        unread_count: 0
      }
    end

    it 'returns push event payload' do
      expect(push_event_data).to eq(expected_data)
    end
  end

  describe '#lock_event_data' do
    subject(:lock_event_data) { conversation.lock_event_data }

    let(:conversation) do
      build(:conversation, display_id: 505, locked: false)
    end

    it 'returns lock event payload' do
      expect(lock_event_data).to eq(id: 505, locked: false)
    end
  end
end
