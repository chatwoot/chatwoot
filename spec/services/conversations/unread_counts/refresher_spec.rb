require 'rails_helper'

RSpec.describe Conversations::UnreadCounts::Refresher do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:label) { create(:label, account: account, title: 'urgent', show_on_sidebar: true) }
  let(:new_label) { create(:label, account: account, title: 'billing', show_on_sidebar: true) }
  let(:assignee) { create(:user, account: account, role: :agent) }
  let(:other_assignee) { create(:user, account: account, role: :agent) }
  let(:store) { Conversations::UnreadCounts::Store }

  after do
    store.clear_account!(account.id)
  end

  it 'does not update redis when unread caches are not ready' do
    conversation = create_unread_conversation(account: account, inbox: inbox, labels: [label.title])

    expect(described_class.new(conversation).perform).to be(false)
    expect(store.counts_for_keys([store.inbox_key(account.id, inbox.id)])).to eq(store.inbox_key(account.id, inbox.id) => 0)
  end

  it 'adds an unread conversation to base cache' do
    conversation = create(:conversation, account: account, inbox: inbox, agent_last_seen_at: 1.hour.ago)
    conversation.update_labels([label.title])
    store.mark_base_ready!(account.id)

    create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming, created_at: 5.minutes.ago)

    expect(described_class.new(conversation.reload).perform).to be(true)

    expect(store.counts_for_keys(base_keys)).to eq(
      store.inbox_key(account.id, inbox.id) => 1,
      store.label_inbox_key(account.id, label.id, inbox.id) => 1
    )
  end

  it 'returns false when refresh does not change unread counts' do
    conversation = create_unread_conversation(account: account, inbox: inbox, labels: [label.title])
    Conversations::UnreadCounts::Builder.new(account).build_base!

    create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming)

    expect(described_class.new(conversation.reload).perform).to be(false)
    expect(store.counts_for_keys(base_keys)).to eq(
      store.inbox_key(account.id, inbox.id) => 1,
      store.label_inbox_key(account.id, label.id, inbox.id) => 1
    )
  end

  it 'removes a conversation from base cache when it becomes read' do
    conversation = create_unread_conversation(account: account, inbox: inbox, labels: [label.title])
    Conversations::UnreadCounts::Builder.new(account).build_base!

    conversation.update!(agent_last_seen_at: 1.minute.from_now)
    expect(described_class.new(conversation.reload).perform).to be(true)

    expect(store.counts_for_keys(base_keys).values).to all(eq(0))
  end

  it 'moves base label membership when labels change' do
    conversation = create_unread_conversation(account: account, inbox: inbox, labels: [label.title])
    Conversations::UnreadCounts::Builder.new(account).build_base!

    conversation.update_labels([new_label.title])
    expect(described_class.new(conversation.reload, changed_attributes: { label_list: [[label.title], [new_label.title]] }).perform).to be(true)

    expect(store.counts_for_keys([
                                   store.label_inbox_key(account.id, label.id, inbox.id),
                                   store.label_inbox_key(account.id, new_label.id, inbox.id)
                                 ])).to eq(
                                   store.label_inbox_key(account.id, label.id, inbox.id) => 0,
                                   store.label_inbox_key(account.id, new_label.id, inbox.id) => 1
                                 )
  end

  it 'moves assignment-aware membership when assignee changes' do
    conversation = create_unread_conversation(account: account, inbox: inbox, labels: [label.title], assignee: assignee)
    Conversations::UnreadCounts::Builder.new(account).build_assignment!

    conversation.update!(assignee: other_assignee)
    described_class.new(conversation.reload, changed_attributes: { assignee_id: [assignee.id, other_assignee.id] }).perform

    expect(store.counts_for_keys([
                                   store.inbox_assignee_key(account.id, inbox.id, assignee.id),
                                   store.inbox_assignee_key(account.id, inbox.id, other_assignee.id)
                                 ])).to eq(
                                   store.inbox_assignee_key(account.id, inbox.id, assignee.id) => 0,
                                   store.inbox_assignee_key(account.id, inbox.id, other_assignee.id) => 1
                                 )
  end

  def base_keys
    [
      store.inbox_key(account.id, inbox.id),
      store.label_inbox_key(account.id, label.id, inbox.id)
    ]
  end
end
