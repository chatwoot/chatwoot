require 'rails_helper'

describe Agents::DestroyService do
  let!(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:team1) { create(:team, account: account) }
  let!(:inbox) { create(:inbox, account: account) }

  before do
    create(:team_member, team: team1, user: user)
    create(:inbox_member, inbox: inbox, user: user)
    create(:conversation, account: account, assignee: user, inbox: inbox)
  end

  describe '#perform' do
    it 'remove inboxes, teams, and conversations when removed from account' do
      described_class.new(account: account, user: user).perform
      user.reload
      expect(user.teams.length).to eq 0
      expect(user.inboxes.length).to eq 0
      expect(user.notification_settings.length).to eq 0
      expect(user.assigned_conversations.where(account: account).length).to eq 0
    end
  end

  describe '#performance perform' do
    before do
      10.times do |_i|
        create(:conversation, account: account, assignee: user, inbox: inbox)
      end
    end

    it 'update assigned conversations when removed from account' do
      expect(user.assigned_conversations.where(account: account).length).to eq 11
      Conversation.update(assignee: user)

      described_class.new(account: account, user: user).send(:unassign_conversations)
      user.reload
      expect(user.assigned_conversations.where(account: account).length).to eq 0
    end
  end
end
