class ActionCableListener < BaseListener
  include Events::Types

  def conversation_created(event)
    conversation, account, timestamp = extract_conversation_and_account(event)
    send_to_administrators(account.administrators, CONVERSATION_CREATED, conversation.push_event_data)
    send_to_agents(conversation.inbox.members, CONVERSATION_CREATED, conversation.push_event_data)
  end

  def conversation_read(event)
    conversation, account, timestamp = extract_conversation_and_account(event)
    send_to_administrators(account.administrators, CONVERSATION_READ, conversation.push_event_data)
    send_to_agents(conversation.inbox.members, CONVERSATION_READ, conversation.push_event_data)
  end

  def message_created(event)
    message, account, timestamp = extract_message_and_account(event)
    conversation = message.conversation
    send_to_administrators(account.administrators, MESSAGE_CREATED, message.push_event_data)
    send_to_agents(conversation.inbox.members, MESSAGE_CREATED, message.push_event_data)
    send_to_contact(conversation.contact, MESSAGE_CREATED, message)
  end

  def message_updated(event)
    message, account, timestamp = extract_message_and_account(event)
    conversation = message.conversation
    contact = conversation.contact
    members = conversation.inbox.members.pluck(:pubsub_token)
    send_to_members(members, MESSAGE_UPDATED, message.push_event_data)
    send_to_contact(contact, MESSAGE_UPDATED, message)
  end

  def conversation_reopened(event)
    conversation, account, timestamp = extract_conversation_and_account(event)
    send_to_administrators(account.administrators, CONVERSATION_REOPENED, conversation.push_event_data)
    send_to_agents(conversation.inbox.members, CONVERSATION_REOPENED, conversation.push_event_data)
  end

  def conversation_lock_toggle(event)
    conversation, account, timestamp = extract_conversation_and_account(event)
    send_to_administrators(account.administrators, CONVERSATION_LOCK_TOGGLE, conversation.lock_event_data)
    send_to_agents(conversation.inbox.members, CONVERSATION_LOCK_TOGGLE, conversation.lock_event_data)
  end

  def assignee_changed(event)
    conversation, account, timestamp = extract_conversation_and_account(event)
    send_to_administrators(account.administrators, ASSIGNEE_CHANGED, conversation.push_event_data)
    send_to_agents(conversation.inbox.members, ASSIGNEE_CHANGED, conversation.push_event_data)
  end

  def contact_created(event)
    contact, account, timestamp = extract_contact_and_account(event)
    send_to_administrators(account.administrators, CONTACT_CREATED, contact.push_event_data)
    send_to_agents(account.agents, CONTACT_CREATED, contact.push_event_data)
  end

  def contact_updated(event)
    contact, account, timestamp = extract_contact_and_account(event)
    send_to_administrators(account.administrators, CONTACT_UPDATED, contact.push_event_data)
    send_to_agents(account.agents, CONTACT_UPDATED, contact.push_event_data)
  end

  private

  def send_to_administrators(admins, event_name, data)
    admin_tokens = admins.pluck(:pubsub_token)
    return if admin_tokens.blank?

    ::ActionCableBroadcastJob.perform_later(admin_tokens, event_name, data)
  end

  def send_to_agents(agents, event_name, data)
    agent_tokens = agents.pluck(:pubsub_token)
    return if agent_tokens.blank?

    ::ActionCableBroadcastJob.perform_later(agent_tokens, event_name, data)
  end

  def send_to_contact(contact, event_name, message)
    return if message.private?
    return if message.activity?
    return if contact.nil?

    ::ActionCableBroadcastJob.perform_later([contact.pubsub_token], event_name, message.push_event_data)
  end
end
