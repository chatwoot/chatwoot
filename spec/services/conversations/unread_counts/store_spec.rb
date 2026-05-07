require 'rails_helper'

RSpec.describe Conversations::UnreadCounts::Store do
  let(:account_id) { 1 }
  let(:inbox_id) { 2 }
  let(:label_id) { 3 }
  let(:user_id) { 4 }
  let(:conversation_id) { 5 }
  let(:team_id) { 6 }

  after do
    described_class.clear_account!(account_id)
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
  end

  describe 'ready markers' do
    it 'tracks base and assignment readiness independently' do
      expect(described_class.base_ready?(account_id)).to be(false)
      expect(described_class.assignment_ready?(account_id)).to be(false)

      described_class.mark_base_ready!(account_id)
      described_class.mark_assignment_ready!(account_id)

      expect(described_class.base_ready?(account_id)).to be(true)
      expect(described_class.assignment_ready?(account_id)).to be(true)
      expect(ttl_for('UNREAD_CONVERSATIONS::V1::ACCOUNT::1::READY::BASE')).to be_within(5).of(Conversations::UnreadCounts::READY_TTL)
      expect(ttl_for('UNREAD_CONVERSATIONS::V1::ACCOUNT::1::READY::ASSIGNMENT')).to be_within(5).of(Conversations::UnreadCounts::READY_TTL)
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

  def ttl_for(key)
    Redis::Alfred.ttl(key)
  end
end
