require 'rails_helper'

RSpec.describe Conversations::UnreadCounts::Builder do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:label) { create(:label, account: account, title: 'urgent', show_on_sidebar: true) }
  let(:assignee) { create(:user, account: account, role: :agent) }
  let(:team) { create(:team, account: account, allow_auto_assign: false) }
  let(:store) { Conversations::UnreadCounts::Store }

  after do
    store.clear_account!(account.id)
  end

  describe '#build_base!' do
    it 'stores unread open conversations by inbox and label inbox' do
      unread_conversation = create_unread_conversation(account: account, inbox: inbox, labels: [label.title], team: team)
      create_read_conversation
      create_resolved_unread_conversation

      described_class.new(account).build_base!

      expect(store.base_ready?(account.id)).to be(true)
      expect(redis_set_members(store.inbox_key(account.id, inbox.id))).to contain_exactly(unread_conversation.id.to_s)
      expect(redis_set_members(store.label_inbox_key(account.id, label.id, inbox.id))).to contain_exactly(unread_conversation.id.to_s)
      expect(redis_set_members(store.team_inbox_key(account.id, team.id, inbox.id))).to contain_exactly(unread_conversation.id.to_s)
    end

    it 'treats a conversation with only an unread incoming reaction as unread' do
      reaction_only_conversation = create_reaction_only_unread_conversation(account: account, inbox: inbox, labels: [label.title], team: team)
      create_read_conversation

      described_class.new(account).build_base!

      expect(redis_set_members(store.inbox_key(account.id, inbox.id))).to contain_exactly(reaction_only_conversation.id.to_s)
      expect(redis_set_members(store.label_inbox_key(account.id, label.id, inbox.id))).to contain_exactly(reaction_only_conversation.id.to_s)
      expect(redis_set_members(store.team_inbox_key(account.id, team.id, inbox.id))).to contain_exactly(reaction_only_conversation.id.to_s)
    end

    it 'counts a conversation with multiple unread messages and multiple unread reactions exactly once' do
      conversation = create(:conversation, account: account, inbox: inbox, agent_last_seen_at: 1.hour.ago)
      create_list(:message, 3, account: account, inbox: inbox, conversation: conversation, message_type: :incoming, created_at: 5.minutes.ago)
      outgoing_message = create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :outgoing,
                                          created_at: 1.month.ago)
      create_list(:message_reaction, 2, account: account, inbox: inbox, conversation: conversation, message: outgoing_message,
                                        created_at: 5.minutes.ago)

      unread_conversation_ids = described_class.new(account).send(:unread_conversations).pluck(:id)

      expect(unread_conversation_ids).to contain_exactly(conversation.id)
    end

    it 'clears assignment-aware cache data before rebuilding base data' do
      assigned_conversation = create_unread_conversation(
        account: account,
        inbox: inbox,
        labels: [label.title],
        assignee: assignee,
        team: team
      )

      described_class.new(account).build_assignment!
      described_class.new(account).build_base!

      expect(store.assignment_ready?(account.id)).to be(false)
      expect(redis_set_members(store.inbox_assignee_key(account.id, inbox.id, assignee.id))).to be_empty
      expect(redis_set_members(store.inbox_key(account.id, inbox.id))).to contain_exactly(assigned_conversation.id.to_s)
    end
  end

  describe '#build_assignment!' do
    it 'stores unread open conversations by unassigned and assignee dimensions' do
      assigned_conversation = create_unread_conversation(
        account: account,
        inbox: inbox,
        labels: [label.title],
        assignee: assignee,
        team: team
      )
      unassigned_conversation = create_unread_conversation(account: account, inbox: inbox, labels: [label.title], team: team)
      agent_bot_conversation = create_unread_conversation(account: account, inbox: inbox, labels: [label.title], team: team)
      agent_bot_conversation.update!(ai_assignee: create(:agent_bot, account: account))

      described_class.new(account).build_assignment!

      expect(store.assignment_ready?(account.id)).to be(true)
      expect(redis_set_members(store.inbox_assignee_key(account.id, inbox.id, assignee.id))).to contain_exactly(assigned_conversation.id.to_s)
      expect(redis_set_members(store.label_inbox_assignee_key(account.id, label.id, inbox.id, assignee.id))).to contain_exactly(
        assigned_conversation.id.to_s
      )
      expect(redis_set_members(store.team_inbox_assignee_key(account.id, team.id, inbox.id, assignee.id))).to contain_exactly(
        assigned_conversation.id.to_s
      )
      expect(redis_set_members(store.inbox_unassigned_key(account.id, inbox.id))).to contain_exactly(unassigned_conversation.id.to_s)
      expect(redis_set_members(store.label_inbox_unassigned_key(account.id, label.id, inbox.id))).to contain_exactly(
        unassigned_conversation.id.to_s
      )
      expect(redis_set_members(store.team_inbox_unassigned_key(account.id, team.id, inbox.id))).to contain_exactly(
        unassigned_conversation.id.to_s
      )
    end

    it 'treats a conversation with only an unread incoming reaction as unread for the assignee' do
      reaction_only_conversation = create_reaction_only_unread_conversation(account: account, inbox: inbox, assignee: assignee, team: team)

      described_class.new(account).build_assignment!

      expect(redis_set_members(store.inbox_assignee_key(account.id, inbox.id, assignee.id))).to contain_exactly(reaction_only_conversation.id.to_s)
    end
  end

  def create_read_conversation
    conversation = create(:conversation, account: account, inbox: inbox, agent_last_seen_at: 1.minute.from_now)
    create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming)
    conversation
  end

  def create_resolved_unread_conversation
    conversation = create_unread_conversation(account: account, inbox: inbox)
    conversation.update!(status: :resolved)
    conversation
  end

  def redis_set_members(key)
    Redis::Alfred.pipelined { |pipeline| pipeline.smembers(key) }.first
  end
end
