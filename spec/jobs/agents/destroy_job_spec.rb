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
    account.account_users.find_by!(user: user).delete
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

    it 'serializes the membership guard and cleanup with agent additions' do
      expect(account).to receive(:with_lock).and_call_original

      described_class.new.perform(account, user)
    end

    it 'invalidates saved filter snapshots when assigned conversations are unassigned' do
      account.enable_features!(:unread_count_for_filters)

      expect do
        described_class.perform_now(account, user)
      end.to change { store.conversation_version(account.id) }.by(1)
    end

    it 'keeps account data when the user was re-added before the cleanup ran' do
      AccountUser.create!(account: account, user: user, role: :agent)

      described_class.perform_now(account, user)

      expect(user.teams).to contain_exactly(team1)
      expect(user.inboxes).to contain_exactly(inbox)
      expect(user.notification_settings.exists?(account: account)).to be(true)
      expect(user.assigned_conversations.exists?(account: account)).to be(true)
    end
  end
end
