require 'rails_helper'

RSpec.describe Conversations::UnreadCounts::Store do
  let(:account_id) { 1 }
  let(:inbox_id) { 2 }
  let(:label_id) { 3 }
  let(:user_id) { 4 }
  let(:conversation_id) { 5 }
  let(:team_id) { 6 }
  let(:other_user_id) { 8 }

  after do
    described_class.clear_all_account!(account_id)
  end

  describe 'key builders' do
    it 'builds base keys using the Redis key naming convention' do
      expect(described_class.inbox_key(account_id, inbox_id)).to eq(
        'UNREAD_CONVERSATIONS::V1::ACCOUNT::1::INBOX::2'
      )
      expect(described_class.label_inbox_key(account_id, label_id, inbox_id)).to eq(
        'UNREAD_CONVERSATIONS::V1::ACCOUNT::1::LABEL::3::INBOX::2'
      )
      expect(described_class.team_inbox_key(account_id, team_id, inbox_id)).to eq(
        'UNREAD_CONVERSATIONS::V1::ACCOUNT::1::TEAM::6::INBOX::2'
      )
    end

    it 'builds assignment-aware keys using the Redis key naming convention' do
      expect(described_class.inbox_unassigned_key(account_id, inbox_id)).to eq(
        'UNREAD_CONVERSATIONS::V1::ACCOUNT::1::INBOX::2::UNASSIGNED'
      )
      expect(described_class.inbox_assignee_key(account_id, inbox_id, user_id)).to eq(
        'UNREAD_CONVERSATIONS::V1::ACCOUNT::1::INBOX::2::ASSIGNEE::4'
      )
      expect(described_class.label_inbox_unassigned_key(account_id, label_id, inbox_id)).to eq(
        'UNREAD_CONVERSATIONS::V1::ACCOUNT::1::LABEL::3::INBOX::2::UNASSIGNED'
      )
      expect(described_class.label_inbox_assignee_key(account_id, label_id, inbox_id, user_id)).to eq(
        'UNREAD_CONVERSATIONS::V1::ACCOUNT::1::LABEL::3::INBOX::2::ASSIGNEE::4'
      )
      expect(described_class.team_inbox_unassigned_key(account_id, team_id, inbox_id)).to eq(
        'UNREAD_CONVERSATIONS::V1::ACCOUNT::1::TEAM::6::INBOX::2::UNASSIGNED'
      )
      expect(described_class.team_inbox_assignee_key(account_id, team_id, inbox_id, user_id)).to eq(
        'UNREAD_CONVERSATIONS::V1::ACCOUNT::1::TEAM::6::INBOX::2::ASSIGNEE::4'
      )
    end

    it 'builds user filter keys using the Redis key naming convention' do
      expect(described_class.user_mentions_key(account_id, user_id)).to eq(
        'UNREAD_CONVERSATIONS::V1::ACCOUNT::1::USER::4::MENTIONS'
      )
      expect(described_class.user_participating_key(account_id, user_id)).to eq(
        'UNREAD_CONVERSATIONS::V1::ACCOUNT::1::USER::4::PARTICIPATING'
      )
      expect(described_class.user_unattended_key(account_id, user_id)).to eq(
        'UNREAD_CONVERSATIONS::V1::ACCOUNT::1::USER::4::UNATTENDED'
      )
      expect(described_class.user_folder_key(account_id, user_id, 7)).to eq(
        'UNREAD_CONVERSATIONS::V1::ACCOUNT::1::USER::4::FOLDER::7'
      )
    end
  end

  describe 'ready markers' do
    it 'starts with all ready markers missing' do
      expect(described_class.base_ready?(account_id)).to be(false)
      expect(described_class.assignment_ready?(account_id)).to be(false)
      expect(described_class.filters_ready?(account_id, user_id)).to be(false)
    end

    it 'tracks base, assignment, and user filter readiness independently' do
      described_class.mark_base_ready!(account_id)
      described_class.mark_assignment_ready!(account_id)
      described_class.mark_filters_ready!(account_id, user_id)

      expect(described_class.base_ready?(account_id)).to be(true)
      expect(described_class.assignment_ready?(account_id)).to be(true)
      expect(described_class.filters_ready?(account_id, user_id)).to be(true)
      expect(ttl_for('UNREAD_CONVERSATIONS::V1::ACCOUNT::1::READY::BASE')).to be_within(5).of(Conversations::UnreadCounts::READY_TTL)
      expect(ttl_for('UNREAD_CONVERSATIONS::V1::ACCOUNT::1::READY::ASSIGNMENT')).to be_within(5).of(Conversations::UnreadCounts::READY_TTL)
      expect(ttl_for('UNREAD_CONVERSATIONS::V1::ACCOUNT::1::USER::4::READY::FILTERS')).to be_within(5).of(
        Conversations::UnreadCounts::READY_TTL
      )
    end

    it 'tracks filter invalidation versions independently' do
      expect(described_class.filter_version_snapshot(account_id, user_id)).to eq(account: 0, user: 0)

      expect(described_class.clear_user_filters!(account_id, user_id)).to be(false)

      expect(described_class.filter_version_snapshot(account_id, user_id)).to eq(account: 0, user: 1)
      expect(ttl_for(user_filter_version_key)).to be_within(5).of(Conversations::UnreadCounts::SET_TTL)

      expect(described_class.clear_filter_caches!(account_id)).to be(false)

      expect(described_class.filter_version_snapshot(account_id, user_id)).to eq(account: 1, user: 1)
      expect(ttl_for(account_filter_version_key)).to be_within(5).of(Conversations::UnreadCounts::SET_TTL)
    end

    it 'marks filter caches ready only when the invalidation version is current' do
      version_snapshot = described_class.filter_version_snapshot(account_id, user_id)

      expect(described_class.mark_filters_ready_if_current!(account_id, user_id, version_snapshot: version_snapshot)).to be_truthy
      expect(described_class.filters_ready?(account_id, user_id)).to be(true)

      described_class.clear_user_filters!(account_id, user_id)

      expect(described_class.mark_filters_ready_if_current!(account_id, user_id, version_snapshot: version_snapshot)).to be(false)
      expect(described_class.filters_ready?(account_id, user_id)).to be(false)
    end
  end

  describe 'set operations' do
    it 'adds, counts, and removes base memberships' do
      described_class.add_base_membership(
        account_id: account_id,
        inbox_id: inbox_id,
        label_ids: [label_id],
        team_id: team_id,
        conversation_id: conversation_id
      )

      expect(described_class.counts_for_keys(base_keys)).to eq(
        described_class.inbox_key(account_id, inbox_id) => 1,
        described_class.label_inbox_key(account_id, label_id, inbox_id) => 1,
        described_class.team_inbox_key(account_id, team_id, inbox_id) => 1
      )
      expect(base_keys.map { |key| ttl_for(key) }).to all(be_within(5).of(Conversations::UnreadCounts::SET_TTL))

      described_class.remove_base_membership(
        account_id: account_id,
        inbox_ids: [inbox_id],
        label_ids: [label_id],
        team_ids: [team_id],
        conversation_id: conversation_id
      )

      expect(described_class.counts_for_keys(base_keys).values).to all(eq(0))
    end

    it 'checks memberships for a conversation across keys' do
      described_class.add_base_membership(
        account_id: account_id,
        inbox_id: inbox_id,
        label_ids: [label_id],
        team_id: team_id,
        conversation_id: conversation_id
      )

      expect(described_class.memberships_for_keys(base_keys, conversation_id)).to eq(
        described_class.inbox_key(account_id, inbox_id) => true,
        described_class.label_inbox_key(account_id, label_id, inbox_id) => true,
        described_class.team_inbox_key(account_id, team_id, inbox_id) => true
      )
      expect(described_class.memberships_for_keys(base_keys, 999).values).to all(be(false))
    end

    it 'adds, counts, and removes assignment-aware memberships' do
      described_class.add_assignment_membership(
        account_id: account_id,
        inbox_id: inbox_id,
        label_ids: [label_id],
        assignee_id: user_id,
        team_id: team_id,
        conversation_id: conversation_id
      )

      expect(described_class.counts_for_keys(assignment_keys)).to eq(
        described_class.inbox_assignee_key(account_id, inbox_id, user_id) => 1,
        described_class.label_inbox_assignee_key(account_id, label_id, inbox_id, user_id) => 1,
        described_class.team_inbox_assignee_key(account_id, team_id, inbox_id, user_id) => 1
      )
      expect(assignment_keys.map { |key| ttl_for(key) }).to all(be_within(5).of(Conversations::UnreadCounts::SET_TTL))

      described_class.remove_assignment_membership(
        account_id: account_id,
        inbox_ids: [inbox_id],
        label_ids: [label_id],
        assignee_ids: [user_id],
        team_ids: [team_id],
        conversation_id: conversation_id
      )

      expect(described_class.counts_for_keys(assignment_keys).values).to all(eq(0))
    end

    it 'sets expiry on bulk membership writes' do
      described_class.add_memberships(
        account_id: account_id,
        memberships: [{
          inbox_id: inbox_id,
          label_ids: [label_id],
          team_id: team_id,
          conversation_id: conversation_id
        }]
      )

      expect(base_keys.map { |key| ttl_for(key) }).to all(be_within(5).of(Conversations::UnreadCounts::SET_TTL))
    end

    it 'adds, counts, and clears user filter memberships' do
      described_class.add_filter_memberships(
        account_id: account_id,
        user_id: user_id,
        filters: {
          mentions: [conversation_id],
          participating: [conversation_id],
          unattended: [conversation_id]
        },
        folders: { 7 => [conversation_id] }
      )
      described_class.mark_filters_ready!(account_id, user_id)

      expect(described_class.counts_for_keys(user_filter_keys)).to eq(
        described_class.user_mentions_key(account_id, user_id) => 1,
        described_class.user_participating_key(account_id, user_id) => 1,
        described_class.user_unattended_key(account_id, user_id) => 1,
        described_class.user_folder_key(account_id, user_id, 7) => 1
      )
      expect(user_filter_keys.map { |key| ttl_for(key) }).to all(be_within(5).of(Conversations::UnreadCounts::SET_TTL))

      expect(described_class.clear_user_filters!(account_id, user_id)).to be(true)

      expect(described_class.filters_ready?(account_id, user_id)).to be(false)
      expect(described_class.counts_for_keys(user_filter_keys).values).to all(eq(0))
    end

    it 'preserves the user filter build lock when clearing one user filter cache' do
      described_class.add_filter_memberships(
        account_id: account_id,
        user_id: user_id,
        filters: {
          mentions: [conversation_id],
          participating: [conversation_id],
          unattended: [conversation_id]
        },
        folders: { 7 => [conversation_id] }
      )
      described_class.mark_filters_ready!(account_id, user_id)
      Redis::Alfred.set(user_filter_build_lock_key, 'locked')

      expect(described_class.clear_user_filters!(account_id, user_id)).to be(true)

      expect(Redis::Alfred.exists?(user_filter_build_lock_key)).to be(true)
      expect(described_class.filters_ready?(account_id, user_id)).to be(false)
      expect(described_class.counts_for_keys(user_filter_keys).values).to all(eq(0))
    end

    it 'preserves user filter build locks when clearing all account filter caches' do
      described_class.add_filter_memberships(
        account_id: account_id,
        user_id: user_id,
        filters: {
          mentions: [conversation_id],
          participating: [],
          unattended: []
        },
        folders: {}
      )
      described_class.add_filter_memberships(
        account_id: account_id,
        user_id: other_user_id,
        filters: {
          mentions: [conversation_id],
          participating: [],
          unattended: []
        },
        folders: {}
      )
      described_class.mark_filters_ready!(account_id, user_id)
      described_class.mark_filters_ready!(account_id, other_user_id)
      Redis::Alfred.set(user_filter_build_lock_key, 'locked')
      Redis::Alfred.set(user_filter_build_lock_key(other_user_id), 'locked')

      expect(described_class.clear_filter_caches!(account_id)).to be(true)

      expect(Redis::Alfred.exists?(user_filter_build_lock_key)).to be(true)
      expect(Redis::Alfred.exists?(user_filter_build_lock_key(other_user_id))).to be(true)
      expect(described_class.filters_ready?(account_id, user_id)).to be(false)
      expect(described_class.filters_ready?(account_id, other_user_id)).to be(false)
      expect(described_class.counts_for_keys([described_class.user_mentions_key(account_id, user_id)]).values).to all(eq(0))
      expect(described_class.counts_for_keys([described_class.user_mentions_key(account_id, other_user_id)]).values).to all(eq(0))
    end

    it 'clears account memberships without clearing user filter memberships' do
      described_class.mark_base_ready!(account_id)
      described_class.mark_assignment_ready!(account_id)
      described_class.mark_filters_ready!(account_id, user_id)
      described_class.add_base_membership(
        account_id: account_id,
        inbox_id: inbox_id,
        label_ids: [label_id],
        team_id: team_id,
        conversation_id: conversation_id
      )
      described_class.add_assignment_membership(
        account_id: account_id,
        inbox_id: inbox_id,
        label_ids: [label_id],
        assignee_id: user_id,
        team_id: team_id,
        conversation_id: conversation_id
      )
      described_class.add_filter_memberships(
        account_id: account_id,
        user_id: user_id,
        filters: {
          mentions: [conversation_id],
          participating: [],
          unattended: []
        },
        folders: {}
      )
      Redis::Alfred.set(user_filter_build_lock_key, 'locked')

      described_class.clear_account!(account_id)

      expect(described_class.base_ready?(account_id)).to be(false)
      expect(described_class.assignment_ready?(account_id)).to be(false)
      expect(described_class.filters_ready?(account_id, user_id)).to be(true)
      expect(described_class.counts_for_keys(base_keys).values).to all(eq(0))
      expect(described_class.counts_for_keys(assignment_keys).values).to all(eq(0))
      expect(described_class.counts_for_keys([described_class.user_mentions_key(account_id, user_id)]).values).to all(eq(1))
      expect(Redis::Alfred.exists?(user_filter_build_lock_key)).to be(true)
    end

    it 'clears all account unread count keys' do
      described_class.mark_base_ready!(account_id)
      described_class.mark_assignment_ready!(account_id)
      described_class.mark_filters_ready!(account_id, user_id)
      described_class.add_base_membership(
        account_id: account_id,
        inbox_id: inbox_id,
        label_ids: [label_id],
        team_id: team_id,
        conversation_id: conversation_id
      )
      described_class.add_assignment_membership(
        account_id: account_id,
        inbox_id: inbox_id,
        label_ids: [label_id],
        assignee_id: user_id,
        team_id: team_id,
        conversation_id: conversation_id
      )
      described_class.add_filter_memberships(
        account_id: account_id,
        user_id: user_id,
        filters: {
          mentions: [conversation_id],
          participating: [],
          unattended: []
        },
        folders: {}
      )
      Redis::Alfred.set(user_filter_build_lock_key, 'locked')

      described_class.clear_all_account!(account_id)

      expect(described_class.base_ready?(account_id)).to be(false)
      expect(described_class.assignment_ready?(account_id)).to be(false)
      expect(described_class.filters_ready?(account_id, user_id)).to be(false)
      expect(described_class.counts_for_keys(base_keys).values).to all(eq(0))
      expect(described_class.counts_for_keys(assignment_keys).values).to all(eq(0))
      expect(described_class.counts_for_keys([described_class.user_mentions_key(account_id, user_id)]).values).to all(eq(0))
      expect(Redis::Alfred.exists?(user_filter_build_lock_key)).to be(false)
    end
  end

  def base_keys
    [
      described_class.inbox_key(account_id, inbox_id),
      described_class.label_inbox_key(account_id, label_id, inbox_id),
      described_class.team_inbox_key(account_id, team_id, inbox_id)
    ]
  end

  def assignment_keys
    [
      described_class.inbox_assignee_key(account_id, inbox_id, user_id),
      described_class.label_inbox_assignee_key(account_id, label_id, inbox_id, user_id),
      described_class.team_inbox_assignee_key(account_id, team_id, inbox_id, user_id)
    ]
  end

  def user_filter_keys(filter_user_id = user_id)
    [
      described_class.user_mentions_key(account_id, filter_user_id),
      described_class.user_participating_key(account_id, filter_user_id),
      described_class.user_unattended_key(account_id, filter_user_id),
      described_class.user_folder_key(account_id, filter_user_id, 7)
    ]
  end

  def user_filter_build_lock_key(filter_user_id = user_id)
    format(Redis::Alfred::UNREAD_CONVERSATIONS_USER_FILTERS_BUILD_LOCK, account_id: account_id, user_id: filter_user_id)
  end

  def account_filter_version_key
    format(Redis::Alfred::UNREAD_CONVERSATIONS_FILTERS_VERSION, account_id: account_id)
  end

  def user_filter_version_key(filter_user_id = user_id)
    format(Redis::Alfred::UNREAD_CONVERSATIONS_USER_FILTERS_VERSION, account_id: account_id, user_id: filter_user_id)
  end

  def ttl_for(key)
    Redis::Alfred.ttl(key)
  end
end
