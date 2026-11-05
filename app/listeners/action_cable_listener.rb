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
    notification_data = event.data[:notification_data]

    user = User.find_by(id: notification_data[:user_id])
    account = Account.find_by(id: notification_data[:account_id])
    return if user.blank? || account.blank?

    notification_finder = NotificationFinder.new(user, account)
    tokens = [user.pubsub_token]
    broadcast(account, tokens, NOTIFICATION_DELETED, {
                notification: { id: notification_data[:id] },
                unread_count: notification_finder.unread_count,
                count: notification_finder.count
              })
  end

  def account_cache_invalidated(event)
    account = event.data[:account]
    tokens = user_tokens(account, account.agents)

    broadcast(account, tokens, ACCOUNT_CACHE_INVALIDATED, {
                cache_keys: event.data[:cache_keys]
              })
  end

  def message_created(event)
    broadcast_message_event(event.data[:message], MESSAGE_CREATED)
  end

  def message_updated(event)
    broadcast_message_event(event.data[:message], MESSAGE_UPDATED, previous_changes: event.data[:previous_changes])
  end

  def first_reply_created(event)
    message, account = extract_message_and_account(event)
    conversation = message.conversation
    tokens = user_tokens(account, conversation.inbox.members)

    broadcast(account, tokens, FIRST_REPLY_CREATED, message.push_event_data)
  end

  def conversation_created(event)
    broadcast_conversation_event(event.data[:conversation], CONVERSATION_CREATED)
  end

  def conversation_bot_handoff(event)
    broadcast_to_inbox_members(event, CONVERSATION_BOT_HANDOFF)
  end

  def conversation_read(event)
    broadcast_to_inbox_members(event, CONVERSATION_READ)
  end

  def conversation_status_changed(event)
    broadcast_conversation_event(event.data[:conversation], CONVERSATION_STATUS_CHANGED)
  end

  def conversation_updated(event)
    broadcast_conversation_event(event.data[:conversation], CONVERSATION_UPDATED)
  end

  def conversation_unread_count_changed(event)
    account, inbox_members = ::Conversations::UnreadCounts::BroadcastScope.new(event).perform
    return if account.blank? || !account.feature_enabled?('conversation_unread_counts')

    tokens = user_tokens(account, inbox_members)

    broadcast(account, tokens, CONVERSATION_UNREAD_COUNT_CHANGED, {})
  end

  def conversation_typing_on(event)
    broadcast_typing_event(event, CONVERSATION_TYPING_ON)
  end

  def conversation_typing_off(event)
    broadcast_typing_event(event, CONVERSATION_TYPING_OFF)
  end

  def assignee_changed(event)
    # Model callbacks identify automatic assignment (auto-assignment or automation
    # rules) by performed_by. The V2 AssignmentService also dispatches an event with
    # user (the assigned agent, NOT the performer). Neither requires inferring
    # automation from a missing Current.user.
    automatic_assignment = [Inbox, AssignmentPolicy, AutomationRule].include?(event.data[:performed_by].class) || event.data[:user].present?
    broadcast_to_inbox_members(event, ASSIGNEE_CHANGED, automatic_assignment: automatic_assignment)
  end

  def team_changed(event)
    broadcast_to_inbox_members(event, TEAM_CHANGED)
  end

  def conversation_contact_changed(event)
    broadcast_to_inbox_members(event, CONVERSATION_CONTACT_CHANGED)
  end

  def contact_created(event)
    contact, account = extract_contact_and_account(event)
    broadcast(account, [account_token(account)], CONTACT_CREATED, contact.push_event_data)
  end

  def contact_updated(event)
    contact, account = extract_contact_and_account(event)
    broadcast(account, [account_token(account)], CONTACT_UPDATED, contact.push_event_data)
  end

  def contact_merged(event)
    contact, account = extract_contact_and_account(event)
    broadcast(account, [account_token(account)], CONTACT_MERGED, contact.push_event_data)
  end

  def contact_deleted(event)
    contact_data = event.data[:contact_data]
    account = Account.find_by(id: contact_data[:account_id])
    return if account.blank?

    broadcast(account, [account_token(account)], CONTACT_DELETED, contact_data)
  end

  def conversation_mentioned(event)
    conversation, account = extract_conversation_and_account(event)
    user = event.data[:user]

    broadcast(account, [user.pubsub_token], CONVERSATION_MENTIONED, conversation.push_event_data)
  end

  private

  def broadcast_to_inbox_members(event, event_name, **metadata)
    conversation, account = extract_conversation_and_account(event)

    broadcast(account, user_tokens(account, conversation.inbox.members), event_name, conversation.push_event_data.merge(metadata))
  end

  def account_token(account)
    "account_#{account.id}"
  end

  def broadcast_message_event(message, event_name, **extra)
    conversation = message.conversation
    agent_tokens = user_tokens(conversation.account, conversation.inbox.members)

    broadcast(conversation.account, agent_tokens, event_name, message.push_event_data.merge(extra))
    broadcast_to_contact(conversation, contact_tokens(conversation.contact_inbox, message), event_name) do |widget|
      event_data_for(message, widget).merge(extra)
    end
  end

  def broadcast_conversation_event(conversation, event_name)
    agent_tokens = user_tokens(conversation.account, conversation.inbox.members)

    broadcast(conversation.account, agent_tokens, event_name, conversation.push_event_data)
    broadcast_to_contact(conversation, contact_inbox_tokens(conversation.contact_inbox), event_name) do |widget|
      event_data_for(conversation, widget)
    end
  end

  def broadcast_typing_event(event, event_name)
    conversation = event.data[:conversation]
    user = event.data[:user]
    is_private = event.data[:is_private] || false

    broadcast(conversation.account, typing_agent_tokens(conversation, user), event_name,
              { conversation: conversation.push_event_data, user: user.push_event_data, is_private: is_private })
    broadcast_to_contact(conversation, typing_contact_tokens(conversation, user), event_name) do |widget|
      { conversation: event_data_for(conversation, widget), user: user.push_event_data, is_private: is_private }
    end
  end

  # Web widget sessions get the widget payload. Client API sessions keep the documented payload.
  def broadcast_to_contact(conversation, tokens, event_name)
    return if tokens.blank?

    widget = conversation.inbox.web_widget?
    job_options = widget ? { widget: true } : {}
    broadcast(conversation.account, tokens, event_name, yield(widget), **job_options)
  end

  def event_data_for(record, widget)
    widget ? record.widget_push_event_data : record.push_event_data
  end

  # Whoever is typing does not get their own typing event
  def typing_agent_tokens(conversation, user)
    tokens = user_tokens(conversation.account, conversation.inbox.members)
    user.respond_to?(:pubsub_token) ? tokens - [user.pubsub_token] : tokens
  end

  def typing_contact_tokens(conversation, user)
    user.is_a?(Contact) ? [] : [conversation.contact_inbox.pubsub_token]
  end

  def user_tokens(account, agents)
    agent_tokens = agents.pluck(:pubsub_token)
    admin_tokens = account.administrators.pluck(:pubsub_token)
    (agent_tokens + admin_tokens).uniq
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

  def broadcast(account, tokens, event_name, data, **job_options)
    return if tokens.blank?

    payload = data.merge(account_id: account.id)
    # So the frondend knows who performed the action.
    # Useful in cases like conversation assignment for generating a notification with assigner name.
    payload[:performer] = Current.user&.push_event_data if Current.user.present?

    ::ActionCableBroadcastJob.perform_later(tokens.uniq, event_name, payload, **job_options)
  end
end

ActionCableListener.prepend_mod_with('ActionCableListener')
