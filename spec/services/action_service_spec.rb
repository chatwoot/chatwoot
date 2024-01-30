require 'rails_helper'

describe ActionService do
  let(:account) { create(:account) }

  describe '#resolve_conversation' do
    let(:conversation) { create(:conversation) }
    let(:action_service) { described_class.new(conversation) }

    it 'resolves the conversation' do
      expect(conversation.status).to eq('open')
      action_service.resolve_conversation(nil)
      expect(conversation.reload.status).to eq('resolved')
    end
  end

  describe '#change_priority' do
    let(:conversation) { create(:conversation) }
    let(:action_service) { described_class.new(conversation) }

    it 'changes the priority of the conversation to medium' do
      action_service.change_priority(['medium'])
      expect(conversation.reload.priority).to eq('medium')
    end

    it 'changes the priority of the conversation to nil' do
      action_service.change_priority(['nil'])
      expect(conversation.reload.priority).to be_nil
    end
  end

  describe '#assign_agent' do
    let(:agent) { create(:user, account: account, role: :agent) }
    let(:conversation) { create(:conversation, account: account) }
    let(:inbox_member) { create(:inbox_member, inbox: conversation.inbox, user: agent) }
    let(:action_service) { described_class.new(conversation) }

    it 'unassigns the conversation if agent id is nil' do
      action_service.assign_agent(['nil'])
      expect(conversation.reload.assignee).to be_nil
    end

    it 'unassigns the team if team_id is nil' do
      action_service.assign_team([nil])
      expect(conversation.reload.team).to be_nil
    end
  end
end
