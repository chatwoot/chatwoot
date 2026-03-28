require 'rails_helper'

RSpec.describe Conversations::PermissionFilterService do
  let(:account) { create(:account) }
  let!(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let!(:another_conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let!(:inbox) { create(:inbox, account: account) }

  # This inbox_member is used to establish the agent's access to the inbox
  before { create(:inbox_member, user: agent, inbox: inbox) }

  describe '#perform' do
    context 'when user is an administrator' do
      it 'returns all conversations' do
        result = described_class.new(
          account.conversations,
          admin,
          account
        ).perform

        expect(result).to include(conversation)
        expect(result).to include(another_conversation)
        expect(result.count).to eq(2)
      end
    end

    context 'when user is an agent' do
      it 'returns all conversations with no further filtering' do
        inbox_ids = agent.inboxes.where(account_id: account.id).pluck(:id)

        # The base implementation returns all conversations
        # expecting the caller to filter by assigned inboxes
        result = described_class.new(
          account.conversations.where(inbox_id: inbox_ids),
          agent,
          account
        ).perform

        expect(result).to include(conversation)
        expect(result).to include(another_conversation)
        expect(result.count).to eq(2)
      end
    end

    context 'when user is an agent with participating_only enabled' do
      let!(:assigned_conversation) { create(:conversation, account: account, inbox: inbox, assignee: agent) }
      let!(:unassigned_conversation) { create(:conversation, account: account, inbox: inbox) }
      let!(:other_agent_conversation) { create(:conversation, account: account, inbox: inbox, assignee: create(:user, account: account)) }

      before do
        # Enable participating_only for this agent
        account_user = AccountUser.find_by(account: account, user: agent)
        account_user.update!(participating_only: true)
      end

      it 'returns only conversations assigned to the agent' do
        result = described_class.new(
          account.conversations,
          agent,
          account
        ).perform

        expect(result).to include(assigned_conversation)
        expect(result).not_to include(unassigned_conversation)
        expect(result).not_to include(other_agent_conversation)
        expect(result.count).to eq(1)
      end

      it 'loses access when conversation is reassigned' do
        # Initially assigned to agent
        assigned_conversation.update!(assignee: agent)

        result = described_class.new(
          account.conversations,
          agent,
          account
        ).perform

        expect(result).to include(assigned_conversation)

        # Reassign to another agent
        other_agent = create(:user, account: account)
        assigned_conversation.update!(assignee: other_agent)

        result = described_class.new(
          account.conversations,
          agent,
          account
        ).perform

        expect(result).not_to include(assigned_conversation)
      end

      it 'does not have access to conversations in inbox if not assigned' do
        inbox_ids = agent.inboxes.where(account_id: account.id).pluck(:id)

        result = described_class.new(
          account.conversations.where(inbox_id: inbox_ids),
          agent,
          account
        ).perform

        # Should only see assigned conversation, not all conversations in the inbox
        expect(result.count).to eq(1)
        expect(result).to include(assigned_conversation)
      end
    end
  end
end
