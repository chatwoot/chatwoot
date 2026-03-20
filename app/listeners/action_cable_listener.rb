class ActionCableListener < BaseListener # rubocop:disable Metrics/ClassLength
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
    message, account = extract_message_and_account(event)
    conversation = message.conversation
    tokens = user_tokens(account, conversation.inbox.members) + contact_tokens(conversation.contact_inbox, message)

    broadcast(account, tokens, MESSAGE_CREATED, message.push_event_data)
  end

  def message_updated(event)
    message, account = extract_message_and_account(event)
    conversation = message.conversation
    tokens = user_tokens(account, conversation.inbox.members) + contact_tokens(conversation.contact_inbox, message)

    broadcast(account, tokens, MESSAGE_UPDATED, message.push_event_data.merge(previous_changes: event.data[:previous_changes]))
  end

  def scheduled_message_created(event)
    scheduled_message = event.data[:scheduled_message]
    account = scheduled_message.account
    tokens = user_tokens(account, scheduled_message.conversation.inbox.members)

    broadcast(account, tokens, SCHEDULED_MESSAGE_CREATED, scheduled_message.push_event_data)
  end

  def scheduled_message_updated(event)
    scheduled_message = event.data[:scheduled_message]
    account = scheduled_message.account
    tokens = user_tokens(account, scheduled_message.conversation.inbox.members)

    broadcast(account, tokens, SCHEDULED_MESSAGE_UPDATED, scheduled_message.push_event_data)
  end

  def scheduled_message_deleted(event)
    scheduled_message = event.data[:scheduled_message]
    account = scheduled_message.account
    tokens = user_tokens(account, scheduled_message.conversation.inbox.members)

    broadcast(account, tokens, SCHEDULED_MESSAGE_DELETED, scheduled_message.push_event_data)
  end

  def recurring_scheduled_message_created(event)
    recurring = event.data[:recurring_scheduled_message]
    account = recurring.account
    tokens = user_tokens(account, recurring.conversation.inbox.members)

    broadcast(account, tokens, RECURRING_SCHEDULED_MESSAGE_CREATED, recurring.push_event_data)
  end

  def recurring_scheduled_message_updated(event)
    recurring = event.data[:recurring_scheduled_message]
    account = recurring.account
    tokens = user_tokens(account, recurring.conversation.inbox.members)

    broadcast(account, tokens, RECURRING_SCHEDULED_MESSAGE_UPDATED, recurring.push_event_data)
  end

  def recurring_scheduled_message_deleted(event)
    recurring = event.data[:recurring_scheduled_message]
    account = recurring.account
    tokens = user_tokens(account, recurring.conversation.inbox.members)

    broadcast(account, tokens, RECURRING_SCHEDULED_MESSAGE_DELETED, recurring.push_event_data)
  end

  def first_reply_created(event)
    message, account = extract_message_and_account(event)
    conversation = message.conversation
    tokens = user_tokens(account, conversation.inbox.members)

    broadcast(account, tokens, FIRST_REPLY_CREATED, message.push_event_data)
  end

  def conversation_created(event)
    conversation, account = extract_conversation_and_account(event)
    tokens = user_tokens(account, conversation.inbox.members) + contact_inbox_tokens(conversation.contact_inbox)

    broadcast(account, tokens, CONVERSATION_CREATED, conversation.push_event_data)
  end

  def conversation_read(event)
    conversation, account = extract_conversation_and_account(event)
    tokens = user_tokens(account, conversation.inbox.members)

    broadcast(account, tokens, CONVERSATION_READ, conversation.push_event_data)
  end

  def conversation_status_changed(event)
    conversation, account = extract_conversation_and_account(event)
    tokens = user_tokens(account, conversation.inbox.members) + contact_inbox_tokens(conversation.contact_inbox)

    broadcast(account, tokens, CONVERSATION_STATUS_CHANGED, conversation.push_event_data)
  end

  def conversation_updated(event)
    conversation, account = extract_conversation_and_account(event)
    tokens = user_tokens(account, conversation.inbox.members) + contact_inbox_tokens(conversation.contact_inbox)

    broadcast(account, tokens, CONVERSATION_UPDATED, conversation.push_event_data)
  end

  def conversation_typing_on(event)
    conversation = event.data[:conversation]
    account = conversation.account
    user = event.data[:user]
    tokens = typing_event_listener_tokens(account, conversation, user)

    broadcast(
      account,
      tokens,
      CONVERSATION_TYPING_ON,
      conversation: conversation.push_event_data,
      user: user.push_event_data,
      is_private: event.data[:is_private] || false
    )
  end

  def conversation_typing_off(event)
    conversation = event.data[:conversation]
    account = conversation.account
    user = event.data[:user]
    tokens = typing_event_listener_tokens(account, conversation, user)

    broadcast(
      account,
      tokens,
      CONVERSATION_TYPING_OFF,
      conversation: conversation.push_event_data,
      user: user.push_event_data,
      is_private: event.data[:is_private] || false
    )
  end

  def assignee_changed(event)
    conversation, account = extract_conversation_and_account(event)
    tokens = user_tokens(account, conversation.inbox.members)

    broadcast(account, tokens, ASSIGNEE_CHANGED, conversation.push_event_data)
  end

  def team_changed(event)
    conversation, account = extract_conversation_and_account(event)
    tokens = user_tokens(account, conversation.inbox.members)

    broadcast(account, tokens, TEAM_CHANGED, conversation.push_event_data)
  end

  def conversation_contact_changed(event)
    conversation, account = extract_conversation_and_account(event)
    tokens = user_tokens(account, conversation.inbox.members)

    broadcast(account, tokens, CONVERSATION_CONTACT_CHANGED, conversation.push_event_data)
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

  def contact_group_synced(event)
    contact, account = extract_contact_and_account(event)
    inbox_phone = contact.group_channel&.phone_number
    payload = contact.push_event_data.merge(
      group_members: group_members_data(contact, account),
      inbox_phone_number: inbox_phone,
      is_inbox_admin: inbox_admin_in_group?(contact, inbox_phone)
    )

    broadcast(account, [account_token(account)], CONTACT_GROUP_SYNCED, payload)
  end

  def conversation_mentioned(event)
    conversation, account = extract_conversation_and_account(event)
    user = event.data[:user]

    broadcast(account, [user.pubsub_token], CONVERSATION_MENTIONED, conversation.push_event_data)
  end

  private

  def account_token(account)
    "account_#{account.id}"
  end

  def typing_event_listener_tokens(account, conversation, user)
    current_user_token = if user.is_a?(Contact)
                           conversation.contact_inbox.pubsub_token
                         elsif user.respond_to?(:pubsub_token)
                           user.pubsub_token
                         end

    tokens = user_tokens(account, conversation.inbox.members) + [conversation.contact_inbox.pubsub_token]
    current_user_token.present? ? tokens - [current_user_token] : tokens
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

  def group_members_data(contact, _account)
    GroupMember.active.where(group_contact: contact).includes(:contact).map do |member|
      {
        id: member.id, role: member.role, is_active: member.is_active, group_contact_id: member.group_contact_id,
        contact: { id: member.contact.id, name: member.contact.name, phone_number: member.contact.phone_number,
                   identifier: member.contact.identifier, thumbnail: member.contact.avatar_url }
      }
    end
  end

  def inbox_admin_in_group?(contact, inbox_phone)
    return false if inbox_phone.blank?

    clean = inbox_phone.delete('+')
    GroupMember.active
               .where(group_contact: contact, role: :admin)
               .joins(:contact)
               .exists?(['REPLACE(contacts.phone_number, \'+\', \'\') = ? OR RIGHT(REPLACE(contacts.phone_number, \'+\', \'\'), 8) = RIGHT(?, 8)',
                         clean, clean])
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

ActionCableListener.prepend_mod_with('ActionCableListener')
