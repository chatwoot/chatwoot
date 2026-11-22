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

  describe '#open_conversation' do
    let(:conversation) { create(:conversation, status: :resolved) }
    let(:action_service) { described_class.new(conversation) }

    it 'opens the conversation' do
      conversation.update!(ai_assignee: create(:agent_bot, account: conversation.account))
      expect(conversation.status).to eq('resolved')
      action_service.open_conversation(nil)
      expect(conversation.reload).to have_attributes(status: 'open', ai_assignee_type: nil, assignee_agent_bot_id: nil)
    end
  end

  describe '#change_status' do
    let(:conversation) { create(:conversation, status: :pending) }

    it 'clears AgentBot ownership when changing the status to open' do
      conversation.update!(ai_assignee: create(:agent_bot, account: conversation.account))

      described_class.new(conversation).change_status(['open'])

      expect(conversation.reload).to have_attributes(status: 'open', ai_assignee_type: nil, assignee_agent_bot_id: nil)
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
    let(:inbox_member) { create(:inbox_member, inbox: conversation.inbox, user: agent) }
    let(:conversation) { create(:conversation, :with_assignee, account: account) }
    let(:action_service) { described_class.new(conversation) }

    it 'unassigns the conversation if agent id is nil' do
      action_service.assign_agent(['nil'])
      expect(conversation.reload.assignee).to be_nil
    end

    context 'when agent is confirmed' do
      it 'assigns the agent to the conversation' do
        inbox_member
        action_service.assign_agent([agent.id])
        expect(conversation.reload.assignee).to eq(agent)
      end
    end

    context 'when agent is unconfirmed' do
      let(:unconfirmed_agent) { create(:user, account: account, role: :agent, skip_confirmation: false) }
      let(:unconfirmed_inbox_member) { create(:inbox_member, inbox: conversation.inbox, user: unconfirmed_agent) }

      it 'does not assign unconfirmed agent to the conversation' do
        unconfirmed_inbox_member
        original_assignee = conversation.assignee
        action_service.assign_agent([unconfirmed_agent.id])
        expect(conversation.reload.assignee).to eq(original_assignee)
      end
    end

    context 'when agent is not a member of the inbox' do
      it 'leaves the conversation unchanged and records why the assignment was skipped' do
        original_assignee = conversation.assignee
        allow(Rails.logger).to receive(:warn)

        expect do
          action_service.assign_agent([agent.id])
        end.to have_enqueued_job(Conversations::ActivityMessageJob)
          .with(conversation, hash_including(message_type: :activity,
                                             content: "Conversation could not be assigned to #{agent.name}: not a member of this inbox"))

        expect(conversation.reload.assignee).to eq(original_assignee)
        expect(Rails.logger).to have_received(:warn).with(/assign_agent skipped/)
      end

      it 'assigns the agent if they are an account administrator' do
        administrator = create(:user, account: account, role: :administrator)

        expect do
          action_service.assign_agent([administrator.id])
        end.not_to have_enqueued_job(Conversations::ActivityMessageJob)
          .with(conversation, hash_including(content: /could not be assigned/))

        expect(conversation.reload.assignee).to eq(administrator)
      end
    end

    context 'when the agent does not exist in the account' do
      it 'leaves the conversation unchanged and records why the assignment was skipped' do
        original_assignee = conversation.assignee

        expect do
          action_service.assign_agent([999_999_999])
        end.to have_enqueued_job(Conversations::ActivityMessageJob)
          .with(conversation, hash_including(message_type: :activity,
                                             content: 'Conversation could not be assigned: the agent is unavailable or does not exist'))

        expect(conversation.reload.assignee).to eq(original_assignee)
      end
    end

    context 'when assigning the last responding agent' do
      it 'assigns the last agent who replied publicly' do
        note_author = create(:user, account: account, role: :agent)
        inbox_member
        create(:inbox_member, inbox: conversation.inbox, user: note_author)
        create(:message, message_type: :outgoing, account: account,
                         inbox: conversation.inbox, conversation: conversation, sender: agent)
        create(:message, message_type: :outgoing, private: true, account: account,
                         inbox: conversation.inbox, conversation: conversation, sender: note_author)

        action_service.assign_agent(['last_responding_agent'])

        expect(conversation.reload.assignee).to eq(agent)
      end

      it 'does not assign the conversation when there is no public agent reply' do
        inbox_member
        original_assignee = conversation.assignee
        create(:message, message_type: :outgoing, private: true, account: account,
                         inbox: conversation.inbox, conversation: conversation, sender: agent)

        action_service.assign_agent(['last_responding_agent'])

        expect(conversation.reload.assignee).to eq(original_assignee)
      end
    end

    context 'when the assignee was concurrently changed to the target agent by another writer' do
      it 'does not issue a redundant write' do
        inbox_member
        action_service # instantiate now, so @conversation stays stale relative to the write below
        Conversation.find(conversation.id).update!(assignee_id: agent.id)
        # Read via a fresh query, not `conversation.reload`, which would mutate the same
        # object @conversation points to and silently erase the staleness under test.
        updated_at_before = Conversation.find(conversation.id).updated_at

        action_service.assign_agent([agent.id])

        expect(Conversation.find(conversation.id).updated_at).to eq(updated_at_before)
      end
    end
  end

  describe '#assign_team' do
    let(:agent) { create(:user, account: account, role: :agent) }
    let(:inbox_member) { create(:inbox_member, inbox: conversation.inbox, user: agent) }
    let(:team) { create(:team, name: 'ConversationTeam', account: account) }
    let(:conversation) { create(:conversation, :with_team, account: account) }
    let(:action_service) { described_class.new(conversation) }

    context 'when team_id is not present' do
      it 'unassign the if team_id is "nil"' do
        expect do
          action_service.assign_team(['nil'])
        end.not_to raise_error
        expect(conversation.reload.team).to be_nil
      end

      it 'unassign the if team_id is 0' do
        expect do
          action_service.assign_team([0])
        end.not_to raise_error
        expect(conversation.reload.team).to be_nil
      end
    end

    context 'when team_id is present' do
      it 'assign the team if the team is part of the account' do
        original_team = conversation.team
        expect do
          action_service.assign_team([team.id])
        end.to change { conversation.reload.team }.from(original_team)
      end

      it 'does not assign the team if the team is part of the account' do
        original_team = conversation.team
        invalid_team_id = 999_999_999
        expect do
          action_service.assign_team([invalid_team_id])
        end.not_to change { conversation.reload.team }.from(original_team)
      end

      it 'does not issue a redundant write when the team was concurrently changed to the target team' do
        action_service # instantiate now, so @conversation stays stale relative to the write below
        Conversation.find(conversation.id).update!(team_id: team.id)
        # Read via a fresh query, not `conversation.reload`, which would mutate the same
        # object @conversation points to and silently erase the staleness under test.
        updated_at_before = Conversation.find(conversation.id).updated_at

        action_service.assign_team([team.id])

        expect(Conversation.find(conversation.id).updated_at).to eq(updated_at_before)
      end
    end
  end

  describe '#remove_assigned_agent' do
    let(:conversation) { create(:conversation, :with_assignee, account: account) }
    let(:action_service) { described_class.new(conversation) }

    it 'unassigns the conversation' do
      expect(conversation.reload.assignee).to be_present
      action_service.remove_assigned_agent(nil)
      expect(conversation.reload.assignee).to be_nil
    end
  end
end
