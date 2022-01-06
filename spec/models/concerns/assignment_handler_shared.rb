# frozen_string_literal: true

require 'rails_helper'

shared_examples_for 'assignment_handler' do
  describe '#update_team' do
    let(:conversation) { create(:conversation, assignee: create(:user)) }
    let(:agent) do
      create(:user, email: 'agent@example.com', account: conversation.account, role: :agent)
    end
    let(:team) do
      create(:team, account: conversation.account, allow_auto_assign: false)
    end

    context 'when agent is current user' do
      before do
        Current.user = agent
        create(:team_member, team: team, user: agent)
        create(:inbox_member, user: agent, inbox: conversation.inbox)
        conversation.inbox.reload
      end

      it 'creates team assigned and unassigned message activity' do
        expect(conversation.update(team: team)).to eq true
        expect(conversation.update(team: nil)).to eq true
        expect(Conversations::ActivityMessageJob).to(have_been_enqueued.at_least(:once)
          .with(conversation, { account_id: conversation.account_id, inbox_id: conversation.inbox_id, message_type: :activity,
                                content: "Assigned to #{team.name} by #{agent.name}"  }))
        expect(Conversations::ActivityMessageJob).to(have_been_enqueued.at_least(:once)
          .with(conversation, { account_id: conversation.account_id, inbox_id: conversation.inbox_id, message_type: :activity,
                                content: "Unassigned from #{team.name} by #{agent.name}" }))
      end

      it 'changes assignee to nil if they doesnt belong to the team and allow_auto_assign is false' do
        expect(team.allow_auto_assign).to eq false

        conversation.update(team: team)

        expect(conversation.reload.assignee).to eq nil
      end

      it 'changes assignee to a team member if allow_auto_assign is enabled' do
        team.update!(allow_auto_assign: true)

        conversation.update(team: team)

        expect(conversation.reload.assignee).to eq agent
        expect(Conversations::ActivityMessageJob).to(have_been_enqueued.at_least(:once)
          .with(conversation, { account_id: conversation.account_id, inbox_id: conversation.inbox_id, message_type: :activity,
                                content: "Assigned to #{conversation.assignee.name} via #{team.name} by #{agent.name}" }))
      end

      it 'wont change assignee if he is already a team member' do
        team.update!(allow_auto_assign: true)
        assignee = create(:user, account: conversation.account, role: :agent)
        create(:inbox_member, user: assignee, inbox: conversation.inbox)
        create(:team_member, team: team, user: assignee)
        conversation.update(assignee: assignee)

        conversation.update(team: team)

        expect(conversation.reload.assignee).to eq assignee
      end
    end
  end

  describe '#update_assignee' do
    subject(:update_assignee) { conversation.update_assignee(agent) }

    let(:conversation) { create(:conversation, assignee: nil) }
    let(:agent) do
      create(:user, email: 'agent@example.com', account: conversation.account, role: :agent)
    end
    let(:assignment_mailer) { instance_double(AgentNotifications::ConversationNotificationsMailer, deliver: true) }

    it 'assigns the agent to conversation' do
      expect(update_assignee).to eq(true)
      expect(conversation.reload.assignee).to eq(agent)
    end

    it 'dispaches assignee changed event' do
      # TODO: FIX me
      # expect(EventDispatcherJob).to(have_been_enqueued.at_least(:once).with('assignee.changed', anything, anything, anything, anything))
      expect(EventDispatcherJob).to(have_been_enqueued.at_least(:once))
      expect(update_assignee).to eq(true)
    end

    context 'when agent is current user' do
      before do
        Current.user = agent
      end

      it 'creates self-assigned message activity' do
        expect(update_assignee).to eq(true)
        expect(Conversations::ActivityMessageJob).to(have_been_enqueued.at_least(:once)
          .with(conversation, { account_id: conversation.account_id, inbox_id: conversation.inbox_id,
                                message_type: :activity, content: "#{agent.name} self-assigned this conversation" }))
      end
    end
  end
end
