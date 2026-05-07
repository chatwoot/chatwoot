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
end
