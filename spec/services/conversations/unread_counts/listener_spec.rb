require 'rails_helper'

RSpec.describe Conversations::UnreadCounts::Listener do
  let(:listener) { described_class.instance }
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:notifier) { instance_double(Conversations::UnreadCounts::Notifier, perform: true) }
  let(:filtered_store) { Conversations::UnreadCounts::FilteredCountStore }

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

  it 'refreshes unread count memberships before invalidating filtered counts when an incoming message is created' do
    account.enable_features!(:conversation_unread_counts, :unread_count_for_filters)
    message = create(:message, account: account, inbox: conversation.inbox, conversation: conversation, message_type: :incoming)
    event = Events::Base.new('message.created', Time.zone.now, message: message)
    invalidator = instance_double(Conversations::UnreadCounts::FilteredCountInvalidator)

    allow(Conversations::UnreadCounts::FilteredCountInvalidator).to receive(:new).with(account).and_return(invalidator)
    expect(notifier).to receive(:perform).ordered.and_return(true)
    expect(invalidator).to receive(:conversation_changed!).ordered.and_return(true)

    listener.message_created(event)
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

  it 'invalidates filtered counts when any message is created' do
    account.enable_features!(:unread_count_for_filters)
    message = create(:message, account: account, inbox: conversation.inbox, conversation: conversation, message_type: :outgoing)
    event = Events::Base.new('message.created', Time.zone.now, message: message)

    expect do
      listener.message_created(event)
    end.to change { filtered_store.conversation_version(account.id) }.by(1)
    expect(Conversations::UnreadCounts::Notifier).not_to have_received(:new)
  end

  it 'notifies clients when outgoing message activity changes filtered counts' do
    account.enable_features!(:conversation_unread_counts, :unread_count_for_filters)
    allow(Rails.configuration.dispatcher).to receive(:dispatch)
    message = create(:message, account: account, inbox: conversation.inbox, conversation: conversation, message_type: :outgoing)
    event = Events::Base.new('message.created', Time.zone.now, message: message)

    listener.message_created(event)

    expect(Rails.configuration.dispatcher).to have_received(:dispatch).with(
      'conversation.unread_count_changed',
      kind_of(Time),
      conversation: conversation
    )
  end

  it 'refreshes unread counts when conversation status changes' do
    changed_attributes = { 'status' => %w[open resolved] }
    event = Events::Base.new('conversation.status_changed', Time.zone.now, conversation: conversation, changed_attributes: changed_attributes)

    listener.conversation_status_changed(event)

    expect(Conversations::UnreadCounts::Notifier).to have_received(:new).with(conversation, changed_attributes: changed_attributes)
    expect(notifier).to have_received(:perform)
  end

  it 'refreshes unread count memberships before invalidating filtered counts when conversation status changes' do
    account.enable_features!(:conversation_unread_counts, :unread_count_for_filters)
    changed_attributes = { 'status' => %w[open resolved] }
    event = Events::Base.new('conversation.status_changed', Time.zone.now, conversation: conversation, changed_attributes: changed_attributes)
    invalidator = instance_double(Conversations::UnreadCounts::FilteredCountInvalidator)

    allow(Conversations::UnreadCounts::FilteredCountInvalidator).to receive(:new).with(account).and_return(invalidator)
    expect(notifier).to receive(:perform).ordered.and_return(true)
    expect(invalidator).to receive(:conversation_changed!).ordered.and_return(true)

    listener.conversation_status_changed(event)
  end

  it 'invalidates filtered counts when conversation status changes' do
    account.enable_features!(:unread_count_for_filters)
    changed_attributes = { 'status' => %w[open resolved] }
    event = Events::Base.new('conversation.status_changed', Time.zone.now, conversation: conversation, changed_attributes: changed_attributes)

    expect do
      listener.conversation_status_changed(event)
    end.to change { filtered_store.conversation_version(account.id) }.by(1)
  end

  it 'notifies clients when a status change only affects filtered counts' do
    account.enable_features!(:conversation_unread_counts, :unread_count_for_filters)
    allow(notifier).to receive(:perform).and_return(false)
    allow(Rails.configuration.dispatcher).to receive(:dispatch)
    changed_attributes = { 'status' => %w[pending resolved] }
    event = Events::Base.new('conversation.status_changed', Time.zone.now, conversation: conversation, changed_attributes: changed_attributes)

    listener.conversation_status_changed(event)

    expect(Rails.configuration.dispatcher).to have_received(:dispatch).with(
      'conversation.unread_count_changed',
      kind_of(Time),
      conversation: conversation
    )
  end

  it 'refreshes unread counts when labels change' do
    changed_attributes = { label_list: [%w[old], %w[new]] }
    event = Events::Base.new('conversation.updated', Time.zone.now, conversation: conversation, changed_attributes: changed_attributes)

    listener.conversation_updated(event)

    expect(Conversations::UnreadCounts::Notifier).to have_received(:new).with(conversation, changed_attributes: changed_attributes)
    expect(notifier).to have_received(:perform)
  end

  it 'does not invalidate filtered counts from conversation updated events' do
    account.enable_features!(:unread_count_for_filters)
    event = Events::Base.new('conversation.updated', Time.zone.now, conversation: conversation, changed_attributes: { priority: [nil, 'high'] })

    expect do
      listener.conversation_updated(event)
    end.not_to(change { filtered_store.conversation_version(account.id) })
    expect(Conversations::UnreadCounts::Notifier).not_to have_received(:new)
  end

  it 'notifies clients when filtered conversation fields change' do
    account.enable_features!(:conversation_unread_counts, :unread_count_for_filters)
    allow(Rails.configuration.dispatcher).to receive(:dispatch)
    event = Events::Base.new('conversation.updated', Time.zone.now, conversation: conversation, changed_attributes: { priority: [nil, 'high'] })

    listener.conversation_updated(event)

    expect(Rails.configuration.dispatcher).to have_received(:dispatch).with(
      'conversation.unread_count_changed',
      kind_of(Time),
      conversation: conversation
    )
  end

  it 'ignores conversation updates unrelated to unread count dimensions' do
    event = Events::Base.new('conversation.updated', Time.zone.now, conversation: conversation, changed_attributes: { identifier: %w[old new] })

    listener.conversation_updated(event)

    expect(Conversations::UnreadCounts::Notifier).not_to have_received(:new)
  end

  it 'invalidates filtered counts when the conversation contact changes' do
    account.enable_features!(:unread_count_for_filters)
    event = Events::Base.new('conversation.contact_changed', Time.zone.now, conversation: conversation)

    expect do
      listener.conversation_contact_changed(event)
    end.to change { filtered_store.conversation_version(account.id) }.by(1)
  end

  it 'notifies clients when the conversation contact changes' do
    account.enable_features!(:conversation_unread_counts, :unread_count_for_filters)
    allow(Rails.configuration.dispatcher).to receive(:dispatch)
    event = Events::Base.new('conversation.contact_changed', Time.zone.now, conversation: conversation)

    listener.conversation_contact_changed(event)

    expect(Rails.configuration.dispatcher).to have_received(:dispatch).with(
      'conversation.unread_count_changed',
      kind_of(Time),
      conversation: conversation
    )
  end

  it 'refreshes unread counts when assignee changes' do
    changed_attributes = { assignee_id: [nil, 1] }
    event = Events::Base.new('assignee.changed', Time.zone.now, conversation: conversation, changed_attributes: changed_attributes)

    listener.assignee_changed(event)

    expect(Conversations::UnreadCounts::Notifier).to have_received(:new).with(conversation, changed_attributes: changed_attributes)
    expect(notifier).to have_received(:perform)
  end

  it 'notifies clients when an assignee change only affects filtered counts' do
    account.enable_features!(:conversation_unread_counts, :unread_count_for_filters)
    allow(notifier).to receive(:perform).and_return(false)
    allow(Rails.configuration.dispatcher).to receive(:dispatch)
    changed_attributes = { assignee_id: [nil, 1] }
    event = Events::Base.new('assignee.changed', Time.zone.now, conversation: conversation, changed_attributes: changed_attributes)

    listener.assignee_changed(event)

    expect(Rails.configuration.dispatcher).to have_received(:dispatch).with(
      'conversation.unread_count_changed',
      kind_of(Time),
      conversation: conversation
    )
  end

  it 'refreshes unread count memberships before invalidating filtered counts when assignee changes' do
    account.enable_features!(:conversation_unread_counts, :unread_count_for_filters)
    changed_attributes = { assignee_id: [nil, 1] }
    event = Events::Base.new('assignee.changed', Time.zone.now, conversation: conversation, changed_attributes: changed_attributes)
    invalidator = instance_double(Conversations::UnreadCounts::FilteredCountInvalidator)

    allow(Conversations::UnreadCounts::FilteredCountInvalidator).to receive(:new).with(account).and_return(invalidator)
    expect(notifier).to receive(:perform).ordered.and_return(true)
    expect(invalidator).to receive(:conversation_changed!).ordered.and_return(true)

    listener.assignee_changed(event)
  end

  it 'invalidates filtered counts when a user is mentioned' do
    account.enable_features!(:unread_count_for_filters)
    user = create(:user, account: account)
    event = Events::Base.new('conversation.mentioned', Time.zone.now, conversation: conversation, user: user)

    expect do
      listener.conversation_mentioned(event)
    end.to change { filtered_store.built_in_filter_version(account_id: account.id, user_id: user.id) }.by(1)
  end

  it 'refreshes unread counts when team changes' do
    changed_attributes = { team_id: [nil, 1] }
    event = Events::Base.new('team.changed', Time.zone.now, conversation: conversation, changed_attributes: changed_attributes)

    listener.team_changed(event)

    expect(Conversations::UnreadCounts::Notifier).to have_received(:new).with(conversation, changed_attributes: changed_attributes)
    expect(notifier).to have_received(:perform)
  end

  it 'notifies clients when a team change only affects filtered counts' do
    account.enable_features!(:conversation_unread_counts, :unread_count_for_filters)
    allow(notifier).to receive(:perform).and_return(false)
    allow(Rails.configuration.dispatcher).to receive(:dispatch)
    changed_attributes = { team_id: [nil, 1] }
    event = Events::Base.new('team.changed', Time.zone.now, conversation: conversation, changed_attributes: changed_attributes)

    listener.team_changed(event)

    expect(Rails.configuration.dispatcher).to have_received(:dispatch).with(
      'conversation.unread_count_changed',
      kind_of(Time),
      conversation: conversation
    )
  end

  it 'invalidates filtered counts when a conversation is deleted' do
    account.enable_features!(:unread_count_for_filters)
    conversation_data = deleted_conversation_data(conversation)

    expect do
      listener.conversation_deleted(Events::Base.new('conversation.deleted', Time.zone.now, conversation_data: conversation_data))
    end.to change { filtered_store.conversation_version(account.id) }.by(1)
  end

  it 'notifies clients when a deleted conversation only affects filtered counts' do
    account.enable_features!(:conversation_unread_counts, :unread_count_for_filters)
    conversation_data = deleted_conversation_data(conversation)
    allow(Rails.configuration.dispatcher).to receive(:dispatch)

    listener.conversation_deleted(Events::Base.new('conversation.deleted', Time.zone.now, conversation_data: conversation_data))

    expect(Rails.configuration.dispatcher).to have_received(:dispatch).with(
      'conversation.unread_count_changed',
      kind_of(Time),
      conversation_data: conversation_data.stringify_keys
    )
  ensure
    store.clear_account!(account.id)
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

  it 'removes unread count memberships before invalidating filtered counts when a conversation is deleted' do
    account.enable_features!(:conversation_unread_counts, :unread_count_for_filters)
    conversation_data = deleted_conversation_data(conversation)
    invalidator = instance_double(Conversations::UnreadCounts::FilteredCountInvalidator)

    store.mark_base_ready!(account.id)
    store.add_base_membership(
      account_id: account.id,
      inbox_id: conversation.inbox_id,
      label_ids: [],
      conversation_id: conversation.id
    )

    allow(Conversations::UnreadCounts::FilteredCountInvalidator).to receive(:new).with(account).and_return(invalidator)
    allow(Rails.configuration.dispatcher).to receive(:dispatch)
    expect(store).to receive(:remove_base_membership).ordered.and_call_original
    expect(invalidator).to receive(:conversation_changed!).ordered.and_return(true)

    listener.conversation_deleted(Events::Base.new('conversation.deleted', Time.zone.now, conversation_data: conversation_data))
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
