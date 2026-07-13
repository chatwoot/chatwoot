require 'rails_helper'

RSpec.describe Conversations::TeamAssignmentService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: nil) }
  let(:team) { create(:team, account: account, allow_auto_assign: true) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:other_agent) { create(:user, account: account, role: :agent) }

  before do
    create(:inbox_member, inbox: inbox, user: agent)
    create(:team_member, team: team, user: agent)
    allow(OnlineStatusTracker).to receive(:get_available_users).and_return(
      { agent.id.to_s => 'online' }
    )
  end

  describe '#perform' do
    it 'assigns the team and an online agent via round robin when unassigned' do
      result = described_class.new(conversation: conversation, team_id: team.id).perform

      conversation.reload
      expect(result).to eq(team)
      expect(conversation.team_id).to eq(team.id)
      expect(conversation.assignee_id).to eq(agent.id)
    end

    it 'does not change assignee when current assignee is already on the team' do
      conversation.update!(assignee: agent)

      described_class.new(conversation: conversation, team_id: team.id).perform

      expect(conversation.reload.assignee_id).to eq(agent.id)
    end

    it 'does not auto-assign when team allow_auto_assign is false' do
      team.update!(allow_auto_assign: false)

      described_class.new(conversation: conversation, team_id: team.id).perform

      conversation.reload
      expect(conversation.team_id).to eq(team.id)
      expect(conversation.assignee_id).to be_nil
    end

    it 'does not clear assignee when unassigning the team' do
      conversation.update!(team: team, assignee: agent)

      result = described_class.new(conversation: conversation, team_id: nil).perform

      conversation.reload
      expect(result).to be_nil
      expect(conversation.team_id).to be_nil
      expect(conversation.assignee_id).to eq(agent.id)
    end

    it 'reassigns via round robin when assignee is not on the new team' do
      create(:inbox_member, inbox: inbox, user: other_agent)
      conversation.update!(assignee: other_agent)

      described_class.new(conversation: conversation, team_id: team.id).perform

      conversation.reload
      expect(conversation.team_id).to eq(team.id)
      expect(conversation.assignee_id).to eq(agent.id)
    end
  end
end
