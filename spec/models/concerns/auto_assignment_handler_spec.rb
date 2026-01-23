# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AutoAssignmentHandler do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account, enable_auto_assignment: true) }
  let(:agent) { create(:user, account: account, role: :agent, auto_offline: false) }
  let(:agent2) { create(:user, account: account, role: :agent, auto_offline: false) }

  before do
    create(:inbox_member, inbox: inbox, user: agent)
    create(:inbox_member, inbox: inbox, user: agent2)
    allow(OnlineStatusTracker).to receive(:get_available_users).and_return({
                                                                             agent.id.to_s => 'online',
                                                                             agent2.id.to_s => 'online'
                                                                           })
  end

  describe '#run_auto_assignment' do
    context 'when conversation has a team assigned' do
      let(:team) { create(:team, account: account, allow_auto_assign: true) }
      let(:team_member) { create(:user, account: account, role: :agent, auto_offline: false) }
      let(:non_team_member) { create(:user, account: account, role: :agent, auto_offline: false) }

      before do
        create(:team_member, team: team, user: team_member)
        create(:inbox_member, inbox: inbox, user: team_member)
        create(:inbox_member, inbox: inbox, user: non_team_member)

        allow(OnlineStatusTracker).to receive(:get_available_users).and_return({
                                                                                 team_member.id.to_s => 'online',
                                                                                 non_team_member.id.to_s => 'online'
                                                                               })
      end

      it 'assigns to team member only when team is present' do
        conversation = create(:conversation, inbox: inbox, team: team, status: :pending)

        conversation.update!(status: :open)

        expect(conversation.reload.assignee).to eq(team_member)
      end

      it 'does not assign to non-team member' do
        conversation = create(:conversation, inbox: inbox, team: team, status: :pending)

        conversation.update!(status: :open)

        expect(conversation.reload.assignee).not_to eq(non_team_member)
      end

      it 'leaves unassigned when team has allow_auto_assign false' do
        team.update!(allow_auto_assign: false)
        conversation = create(:conversation, inbox: inbox, team: team, status: :pending)

        conversation.update!(status: :open)

        expect(conversation.reload.assignee).to be_nil
      end

      it 'leaves unassigned when no team members are available' do
        # Make team_member offline
        allow(OnlineStatusTracker).to receive(:get_available_users).and_return({
                                                                                 non_team_member.id.to_s => 'online'
                                                                               })

        conversation = create(:conversation, inbox: inbox, team: team, status: :pending)

        conversation.update!(status: :open)

        expect(conversation.reload.assignee).to be_nil
      end
    end

    context 'when conversation has no team assigned' do
      it 'assigns to any inbox member' do
        conversation = create(:conversation, inbox: inbox, team: nil, status: :pending)

        conversation.update!(status: :open)

        expect(conversation.reload.assignee).to be_in([agent, agent2])
      end
    end
  end
end
