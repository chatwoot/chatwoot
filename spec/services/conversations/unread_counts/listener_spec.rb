require 'rails_helper'

RSpec.describe Conversations::UnreadCounts::Listener do
  let(:listener) { described_class.instance }
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:notifier) { instance_double(Conversations::UnreadCounts::Notifier, perform: true) }

  before do
    allow(Conversations::UnreadCounts::Notifier).to receive(:new).and_return(notifier)
  end

  it 'refreshes unread counts when an incoming message is created' do
    account.enable_features!(:conversation_unread_counts)
    message = create(:message, account: account, inbox: conversation.inbox, conversation: conversation, message_type: :incoming)
    event = Events::Base.new('message.created', Time.zone.now, message: message)

    listener.message_created(event)

    expect(Conversations::UnreadCounts::Notifier).to have_received(:new).with(conversation, changed_attributes: nil)
    expect(notifier).to have_received(:perform)
  end

  it 'ignores outgoing message creation' do
    message = create(:message, account: account, inbox: conversation.inbox, conversation: conversation, message_type: :outgoing)
    event = Events::Base.new('message.created', Time.zone.now, message: message)

    listener.message_created(event)

    expect(Conversations::UnreadCounts::Notifier).not_to have_received(:new)
  end

  it 'ignores incoming message creation when conversation unread counts are disabled' do
    message = create(:message, account: account, inbox: conversation.inbox, conversation: conversation, message_type: :incoming)
    event = Events::Base.new('message.created', Time.zone.now, message: message)

    expect(message).not_to receive(:conversation)

    listener.message_created(event)

    expect(Conversations::UnreadCounts::Notifier).not_to have_received(:new)
  end

  it 'refreshes unread counts when conversation status changes' do
    changed_attributes = { 'status' => %w[open resolved] }
    event = Events::Base.new('conversation.status_changed', Time.zone.now, conversation: conversation, changed_attributes: changed_attributes)

    listener.conversation_status_changed(event)

    expect(Conversations::UnreadCounts::Notifier).to have_received(:new).with(conversation, changed_attributes: changed_attributes)
    expect(notifier).to have_received(:perform)
  end

  it 'refreshes unread counts when labels change' do
    changed_attributes = { label_list: [%w[old], %w[new]] }
    event = Events::Base.new('conversation.updated', Time.zone.now, conversation: conversation, changed_attributes: changed_attributes)

    listener.conversation_updated(event)

    expect(Conversations::UnreadCounts::Notifier).to have_received(:new).with(conversation, changed_attributes: changed_attributes)
    expect(notifier).to have_received(:perform)
  end

  it 'ignores conversation updates unrelated to unread count dimensions' do
    event = Events::Base.new('conversation.updated', Time.zone.now, conversation: conversation, changed_attributes: { priority: [nil, 'high'] })

    listener.conversation_updated(event)

    expect(Conversations::UnreadCounts::Notifier).not_to have_received(:new)
  end

  it 'refreshes unread counts when assignee changes' do
    changed_attributes = { assignee_id: [nil, 1] }
    event = Events::Base.new('assignee.changed', Time.zone.now, conversation: conversation, changed_attributes: changed_attributes)

    listener.assignee_changed(event)

    expect(Conversations::UnreadCounts::Notifier).to have_received(:new).with(conversation, changed_attributes: changed_attributes)
    expect(notifier).to have_received(:perform)
  end

  it 'refreshes unread counts when team changes' do
    changed_attributes = { team_id: [nil, 1] }
    event = Events::Base.new('team.changed', Time.zone.now, conversation: conversation, changed_attributes: changed_attributes)

    listener.team_changed(event)

    expect(Conversations::UnreadCounts::Notifier).to have_received(:new).with(conversation, changed_attributes: changed_attributes)
    expect(notifier).to have_received(:perform)
  end

  it 'removes unread count memberships when a conversation is deleted' do
    account.enable_features!(:conversation_unread_counts)
    label = create(:label, account: account)
    team = create(:team, account: account)
    assignee = create(:user, account: account)
    create(:team_member, team: team, user: assignee)
    conversation.update!(assignee_id: assignee.id, team: team)
    conversation.update_labels([label.title])
    conversation.reload
    conversation_data = deleted_conversation_data(conversation)
    store.mark_base_ready!(account.id)
    store.mark_assignment_ready!(account.id)
    store.add_base_membership(
      account_id: account.id,
      inbox_id: conversation.inbox_id,
      label_ids: [label.id],
      team_id: team.id,
      conversation_id: conversation.id
    )
    store.add_assignment_membership(
      account_id: account.id,
      inbox_id: conversation.inbox_id,
      label_ids: [label.id],
      assignee_id: assignee.id,
      team_id: team.id,
      conversation_id: conversation.id
    )
    allow(Rails.configuration.dispatcher).to receive(:dispatch)

    listener.conversation_deleted(Events::Base.new('conversation.deleted', Time.zone.now, conversation_data: conversation_data))

    expect(store.counts_for_keys(deleted_base_keys(conversation, label, team)).values).to all(eq(0))
    expect(store.counts_for_keys(deleted_assignment_keys(conversation, label, team, assignee)).values).to all(eq(0))
    expect(Rails.configuration.dispatcher).to have_received(:dispatch).with(
      'conversation.unread_count_changed',
      kind_of(Time),
      conversation_data: conversation_data.stringify_keys
    )
  ensure
    store.clear_account!(account.id)
  end

  def deleted_conversation_data(conversation)
    {
      id: conversation.id,
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      assignee_id: conversation.assignee_id,
      team_id: conversation.team_id,
      cached_label_list: conversation.cached_label_list
    }
  end

  def deleted_base_keys(conversation, label, team)
    [
      store.inbox_key(account.id, conversation.inbox_id),
      store.label_inbox_key(account.id, label.id, conversation.inbox_id),
      store.team_inbox_key(account.id, team.id, conversation.inbox_id)
    ]
  end

  def deleted_assignment_keys(conversation, label, team, assignee)
    [
      store.inbox_assignee_key(account.id, conversation.inbox_id, assignee.id),
      store.label_inbox_assignee_key(account.id, label.id, conversation.inbox_id, assignee.id),
      store.team_inbox_assignee_key(account.id, team.id, conversation.inbox_id, assignee.id)
    ]
  end

  def store
    Conversations::UnreadCounts::Store
  end
end
