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
      expect(conversation.status).to eq('resolved')
      action_service.open_conversation(nil)
      expect(conversation.reload.status).to eq('open')
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
    end
  end

  describe '#create_scheduled_message' do
    it 'creates scheduled message with content and delay' do
      conversation = create(:conversation, account: account)
      user = create(:user, account: account)
      Current.user = user
      action_service = described_class.new(conversation)

      action_service.create_scheduled_message([{ content: 'Hello', delay_minutes: 10 }])

      scheduled_message = conversation.scheduled_messages.last

      expect(scheduled_message.content).to eq('Hello')
      expect(scheduled_message.status).to eq('pending')
      expect(scheduled_message.scheduled_at).to be_within(1.minute).of(10.minutes.from_now)
    end

    it 'attaches blob when blob_id is provided' do
      conversation = create(:conversation, account: account)
      user = create(:user, account: account)
      Current.user = user
      action_service = described_class.new(conversation)
      blob = ActiveStorage::Blob.create_and_upload!(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png')

      action_service.create_scheduled_message([{ content: 'With attachment', delay_minutes: 5, blob_id: blob.id }])

      expect(conversation.scheduled_messages.last.attachment).to be_attached
    end
  end
end
