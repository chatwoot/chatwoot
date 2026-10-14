require 'rails_helper'

RSpec.describe Agents::DestroyJob do
  subject(:job) { described_class.perform_later(account, user) }

  let!(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:team1) { create(:team, account: account) }
  let!(:inbox) { create(:inbox, account: account) }
  let(:store) { Conversations::UnreadCounts::FilteredCountStore }

  before do
    create(:team_member, team: team1, user: user)
    create(:inbox_member, inbox: inbox, user: user)
    create(:conversation, account: account, assignee: user, inbox: inbox)
  end

  it 'enqueues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .with(account, user)
      .on_queue('low')
  end

  describe '#perform' do
    it 'remove inboxes, teams, and conversations when removed from account' do
      described_class.perform_now(account, user)

      user.reload
      expect(user.teams.length).to eq 0
      expect(user.inboxes.length).to eq 0
      expect(user.notification_settings.length).to eq 0
      expect(user.assigned_conversations.where(account: account).length).to eq 0
    end

    it 'invalidates saved filter snapshots when assigned conversations are unassigned' do
      account.enable_features!(:unread_count_for_filters)

      expect do
        described_class.perform_now(account, user)
      end.to change { store.conversation_version(account.id) }.by(1)
    end
  end
end
