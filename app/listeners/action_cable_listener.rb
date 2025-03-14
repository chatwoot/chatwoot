class ActionCableListener < BaseListener
  include Events::Types

  def notification_created(event)
    notification, account, unread_count, count = extract_notification_and_account(event)
    tokens = [event.data[:notification].user.pubsub_token]
    broadcast(account, tokens, NOTIFICATION_CREATED, { notification: notification.push_event_data, unread_count: unread_count, count: count })
  end

  def notification_updated(event)
    notification, account, unread_count, count = extract_notification_and_account(event)
    tokens = [event.data[:notification].user.pubsub_token]
    broadcast(account, tokens, NOTIFICATION_UPDATED, { notification: notification.push_event_data, unread_count: unread_count, count: count })
  end

  def notification_deleted(event)
    return if event.data[:notification].user.blank?

    notification, account, unread_count, count = extract_notification_and_account(event)
    tokens = [event.data[:notification].user.pubsub_token]
    broadcast(account, tokens, NOTIFICATION_DELETED, { notification: { id: notification.id }, unread_count: unread_count, count: count })
  end

  def account_cache_invalidated(event)
    account = event.data[:account]
    broadcast(account, account_stream(account), ACCOUNT_CACHE_INVALIDATED, { cache_keys: event.data[:cache_keys] })
  end

  def message_created(event)
    broadcast_message_event(MESSAGE_CREATED, event)
    broadcast_message_event_to_contact(MESSAGE_CREATED, event)
  end

  def message_updated(event)
    broadcast_message_event(MESSAGE_UPDATED, event)
    broadcast_message_event_to_contact(MESSAGE_UPDATED, event)
  end

  def first_reply_created(event)
    broadcast_message_event(FIRST_REPLY_CREATED, event)
  end

  def conversation_created(event)
    broadcast_conversation_event_to_contact(CONVERSATION_CREATED, event)
    broadcast_conversation_event(CONVERSATION_CREATED, event)
  end

  def conversation_read(event)
    broadcast_conversation_event(CONVERSATION_READ, event)
  end

  def conversation_status_changed(event)
    broadcast_conversation_event_to_contact(CONVERSATION_STATUS_CHANGED, event)
    broadcast_conversation_event(CONVERSATION_STATUS_CHANGED, event)
  end

  def conversation_updated(event)
    broadcast_conversation_event_to_contact(CONVERSATION_UPDATED, event)
    broadcast_conversation_event(CONVERSATION_UPDATED, event)
  end

  def conversation_typing_on(event)
    broadcast_typing_event(CONVERSATION_TYPING_ON, event)
  end

  def conversation_typing_off(event)
    broadcast_typing_event(CONVERSATION_TYPING_OFF, event)
  end

  def assignee_changed(event)
    broadcast_conversation_event(ASSIGNEE_CHANGED, event)
  end

  def team_changed(event)
    broadcast_conversation_event(TEAM_CHANGED, event)
  end

  def conversation_contact_changed(event)
    broadcast_conversation_event(CONVERSATION_CONTACT_CHANGED, event)
  end

  def contact_created(event)
    broadcast_contact_event(CONTACT_CREATED, event)
  end

  def contact_updated(event)
    broadcast_contact_event(CONTACT_UPDATED, event)
  end

  def contact_merged(event)
    broadcast_contact_event(CONTACT_MERGED, event)
  end

  def contact_deleted(event)
    broadcast_contact_event(CONTACT_DELETED, event)
  end

  def conversation_mentioned(event)
    conversation, account = extract_conversation_and_account(event)
    user = event.data[:user]

    broadcast(account, [user.pubsub_token], CONVERSATION_MENTIONED, conversation.push_event_data)
  end

  private

  def account_stream(account)
    ["account_#{account.id}"]
  end

  def inbox_stream(inbox)
    ["inbox_#{inbox.id}"]
  end

  def broadcast_contact_event(event_name, event_data)
    contact, account = extract_contact_and_account(event_data)
    broadcast(account, account_stream(account), event_name, contact.push_event_data)
  end

  def broadcast_conversation_event(event_name, event_data)
    conversation, account = extract_conversation_and_account(event_data)
    broadcast(account, inbox_stream(conversation.inbox), event_name, conversation.push_event_data)
  end

  def broadcast_message_event(event_name, event_data)
    message, account = extract_message_and_account(event_data)
    broadcast(account, inbox_stream(message.inbox), event_name, message.push_event_data)
  end

  def broadcast_conversation_event_to_contact(event_name, event_data)
    conversation, account = extract_conversation_and_account(event_data)
    tokens = contact_inbox_tokens(conversation.contact_inbox)
    broadcast(account, tokens, event_name, conversation.push_event_data)
  end

  def broadcast_message_event_to_contact(event_name, event_data)
    message, account = extract_message_and_account(event_data)
    tokens = contact_tokens(message.conversation.contact_inbox, message)
    broadcast(account, tokens, event_name, message.push_event_data)
  end

  def broadcast_typing_event(event_name, event_data)
    conversation = event_data[:conversation]
    account = conversation.account
    user = event_data[:user]
    tokens = typing_event_listener_tokens(account, conversation, user)

    broadcast(
      account,
      tokens,
      event_name,
      conversation: conversation.push_event_data,
      user: user.push_event_data,
      is_private: event.data[:is_private] || false
    )
  end

  def contact_tokens(contact_inbox, message)
    return [] if message.private?
    return [] if message.activity?
    return [] if contact_inbox.nil?

    contact_inbox_tokens(contact_inbox)
  end

  def contact_inbox_tokens(contact_inbox)
    contact = contact_inbox.contact

    contact_inbox.hmac_verified? ? contact.contact_inboxes.where(hmac_verified: true).filter_map(&:pubsub_token) : [contact_inbox.pubsub_token]
  end

  def broadcast(account, tokens, event_name, data)
    return if tokens.blank?

    payload = data.merge(account_id: account.id)
    # So the frondend knows who performed the action.
    # Useful in cases like conversation assignment for generating a notification with assigner name.
    payload[:performer] = Current.user&.push_event_data if Current.user.present?

    ::ActionCableBroadcastJob.perform_later(tokens.uniq, event_name, payload)
  end
end
