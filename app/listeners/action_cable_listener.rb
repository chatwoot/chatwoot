class ActionCableListener < BaseListener
  include Events::Types

  def conversation_created(event)
    conversation, account, timestamp = extract_conversation_and_account(event)
    members = conversation.inbox.members.pluck(:pubsub_token)
    send_to_members(members, CONVERSATION_CREATED, conversation.push_event_data)
  end

  def conversation_read(event)
    conversation, account, timestamp = extract_conversation_and_account(event)
    members = conversation.inbox.members.pluck(:pubsub_token)
    send_to_members(members, CONVERSATION_READ, conversation.push_event_data)
  end

  def message_created(event)
    message, account, timestamp = extract_message_and_account(event)
    conversation = message.conversation
    contact = conversation.contact
    members = conversation.inbox.members.pluck(:pubsub_token)
    send_to_members(members, MESSAGE_CREATED, message.push_event_data)
    send_to_contact(contact, MESSAGE_CREATED, message)
  end

  def conversation_reopened(event)
    conversation, account, timestamp = extract_conversation_and_account(event)
    members = conversation.inbox.members.pluck(:pubsub_token)
    send_to_members(members, CONVERSATION_REOPENED, conversation.push_event_data)
  end

  def conversation_lock_toggle(event)
    conversation, account, timestamp = extract_conversation_and_account(event)
    members = conversation.inbox.members.pluck(:pubsub_token)
    send_to_members(members, CONVERSATION_LOCK_TOGGLE, conversation.lock_event_data)
  end

  def assignee_changed(event)
    conversation, account, timestamp = extract_conversation_and_account(event)
    members = conversation.inbox.members.pluck(:pubsub_token)
    send_to_members(members, ASSIGNEE_CHANGED, conversation.push_event_data)
  end

  private

  def send_to_members(members, event_name, data)
    return if members.blank?

    members.each do |member|
      ActionCable.server.broadcast(member, event: event_name, data: data)
    end
  end

  def send_to_contact(contact, event_name, message)
    return if message.private?
    return if message.activity?
    return if contact.nil?

    ActionCable.server.broadcast(contact.pubsub_token, event: event_name, data: message.push_event_data)
  end

  def push(pubsub_token, data)
    # Enqueue sidekiq job to push event to corresponding channel
  end
end
