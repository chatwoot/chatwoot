require 'rails_helper'

RSpec.describe AutoAssignment::AgentAssignmentService do
  let!(:account) { create(:account) }
  let!(:inbox) { create(:inbox, account: account, enable_auto_assignment: false) }
  let!(:inbox_members) { create_list(:inbox_member, 5, inbox: inbox) }
  let!(:conversation) { create(:conversation, inbox: inbox, account: account) }
  let!(:online_users) do
    {
      inbox_members[0].user_id.to_s => 'busy',
      inbox_members[1].user_id.to_s => 'busy',
      inbox_members[2].user_id.to_s => 'busy',
      inbox_members[3].user_id.to_s => 'online',
      inbox_members[4].user_id.to_s => 'online'
    }
  end

  before do
    inbox_members.each do |member|
      create(:account_user, account: account, user: member.user)
    end

    allow(OnlineStatusTracker).to receive(:get_available_users)
      .and_return(online_users)
  end

  describe '#perform' do
    it 'assigns an online agent with the fewest active chats' do
      expect(conversation.assignee).to be_nil

      described_class.new(
        conversation: conversation,
        allowed_agent_ids: inbox_members.map(&:user_id).map(&:to_s)
      ).perform

      expect(conversation.reload.assignee).not_to be_nil
      expect([inbox_members[3].user, inbox_members[4].user]).to include(conversation.assignee)
    end
  end

  describe '#find_assignee' do
    it 'returns an online agent with the fewest open chats' do
      create(:conversation, :open, inbox: inbox, assignee: inbox_members[3].user, account: account)
      create(:conversation, :open, inbox: inbox, assignee: inbox_members[3].user, account: account)
      create(:conversation, :open, inbox: inbox, assignee: inbox_members[4].user, account: account)

      assignee = described_class.new(
        conversation: conversation,
        allowed_agent_ids: inbox_members.map(&:user_id).map(&:to_s)
      ).find_assignee

      expect(assignee).to eq(inbox_members[4].user)
    end

    it 'returns nil if no online agents available' do
      allow(OnlineStatusTracker).to receive(:get_available_users)
        .and_return({})

      assignee = described_class.new(
        conversation: conversation,
        allowed_agent_ids: inbox_members.map(&:user_id).map(&:to_s)
      ).find_assignee

      expect(assignee).to be_nil
    end

    it 'does not select agents who reached their limit' do
      account_user = AccountUser.find_by(user: inbox_members[3].user, account: account)
      account_user.update!(active_chat_limit_enabled: true, active_chat_limit: 1)

      create(:conversation, :open, inbox: inbox, assignee: inbox_members[3].user, account: account)

      assignee = described_class.new(
        conversation: conversation,
        allowed_agent_ids: inbox_members.map(&:user_id).map(&:to_s)
      ).find_assignee

      expect(assignee).to eq(inbox_members[4].user)
    end
  end
end
