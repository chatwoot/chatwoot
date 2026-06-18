require 'rails_helper'

RSpec.describe ConversationFinder do
  describe '#perform' do
    it 'returns participant-only conversations for custom roles with participating permission' do
      account = create(:account)
      agent = create(:user, account: account, role: :agent)
      other_agent = create(:user, account: account, role: :agent)
      inbox = create(:inbox, account: account, enable_auto_assignment: false)
      custom_role = create(:custom_role, account: account, permissions: ['conversation_participating_manage'])
      participating_conversation = create(:conversation, account: account, inbox: inbox, assignee: other_agent)

      create(:inbox_member, user: agent, inbox: inbox)
      create(:inbox_member, user: other_agent, inbox: inbox)
      create(:conversation_participant, account: account, conversation: participating_conversation, user: agent)
      account.account_users.find_by!(user_id: agent.id).update!(custom_role: custom_role)
      Current.account = account

      result = described_class.new(agent, { status: 'open', conversation_type: 'participating' }).perform

      expect(result[:conversations].map(&:id)).to include(participating_conversation.id)
    end
  end
end
