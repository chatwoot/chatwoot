class ActionCableListener < BaseListener # rubocop:disable Metrics/ClassLength
  include Events::Types

  def notification_created(event)
    return unless event.data[:notification].visible_to_recipient?

    notification, account, unread_count, count = extract_notification_and_account(event)
    tokens = [event.data[:notification].user.pubsub_token]
    broadcast(account, tokens, NOTIFICATION_CREATED, { notification: notification.push_event_data, unread_count: unread_count, count: count })
  end

  def notification_updated(event)
    return unless event.data[:notification].visible_to_recipient?

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

  def inbox_provider_connection_updated(event)
    inbox = event.data[:inbox]
    account = inbox.account
    provider_connection = event.data[:provider_connection] || {}

    # QR code / error are admin-only (mirrors Channel::Whatsapp#provider_connection_data):
    # the QR grants full access to the WhatsApp account, so it must not reach agents.
    # Agents and admins receive different payloads (admins also get qr_data_url/error,
    # which grant full WhatsApp account access), so the two recipient lists are built
    # separately. Querying each role directly also avoids `user_tokens` re-querying
    # administrators. The roles are disjoint, so the lists never overlap.
    admin_tokens = account.administrators.pluck(:pubsub_token)
    agent_tokens = account.agents.pluck(:pubsub_token)

    # The agent half is shared with the REST payload, and it is the whole hash a connection
    # update replaces on the frontend: a key left out here drops its banner until reload.
    connection = inbox.channel.provider_connection_agent_data(provider_connection)
    broadcast(account, agent_tokens, INBOX_PROVIDER_CONNECTION_UPDATED, { inbox_id: inbox.id, provider_connection: connection })
    broadcast(account, admin_tokens, INBOX_PROVIDER_CONNECTION_UPDATED, {
                inbox_id: inbox.id,
                provider_connection: connection.merge(inbox.channel.provider_connection_admin_data(provider_connection))
              })
  end

  def message_created(event)
    broadcast_message_event(event.data[:message], MESSAGE_CREATED)
  end

  def message_updated(event)
    broadcast_message_event(event.data[:message], MESSAGE_UPDATED, previous_changes: event.data[:previous_changes])
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
    metadata = event.data[:broadcast_metadata]
    broadcast_conversation_event(event.data[:conversation], CONVERSATION_UPDATED, metadata.present? ? { event_metadata: metadata } : {})
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

  def conversation_recording(event)
    broadcast_typing_event(event, CONVERSATION_RECORDING)
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

  def contact_group_synced(event)
    contact, account = extract_contact_and_account(event)
    # The inbox the sync actually ran as. `Contact#group_channel` is the group contact's
    # first contact inbox, which is an arbitrary pick as soon as the same group is in two
    # inboxes of one account: it would answer "you administer this group" for a number
    # that is not the one the agent has open. Kept as the fallback for an event queued by
    # a version that did not name it.
    channel = event.data[:channel] || contact.group_channel
    # The same answer the REST roster sends, from the same lookup. Two copies of it is how
    # an account known by LID alone was recognised by whichever ran last: the fetch said
    # "you administer this group" and the first sync event took it back.
    own_member = Whatsapp::Session::Owner.group_member(channel, contact)
    payload = contact.push_event_data.merge(
      group_members: group_members_data(contact, account),
      inbox_id: channel&.inbox&.id,
      inbox_phone_number: channel&.phone_number,
      own_member_id: own_member&.id,
      is_inbox_admin: own_member&.role == 'admin'
    )

    broadcast(account, [account_token(account)], CONTACT_GROUP_SYNCED, payload)
  end

  def conversation_mentioned(event)
    conversation, account = extract_conversation_and_account(event)
    user = event.data[:user]

    broadcast(account, [user.pubsub_token], CONVERSATION_MENTIONED, conversation.push_event_data)
  end

  def conversation_pinned(event)
    broadcast_conversation_pin(event, CONVERSATION_PINNED)
  end

  def conversation_unpinned(event)
    broadcast_conversation_pin(event, CONVERSATION_UNPINNED)
  end

  private

  def broadcast_to_inbox_members(event, event_name, **metadata)
    conversation, account = extract_conversation_and_account(event)

    broadcast(account, user_tokens(account, conversation.inbox.members), event_name, conversation.push_event_data.merge(metadata))
  end

  # Pins are personal, so the event only reaches the sessions of the agent who pinned the conversation.
  def broadcast_conversation_pin(event, event_name)
    pin_data = event.data[:conversation_pin]

    user = User.find_by(id: pin_data[:user_id])
    account = Account.find_by(id: pin_data[:account_id])
    return if user.blank? || account.blank?

    broadcast(account, [user.pubsub_token], event_name, {
                conversation_id: pin_data[:conversation_id],
                pinned_at: pin_data[:pinned_at]
              })
  end

  def account_token(account)
    "account_#{account.id}"
  end

  def broadcast_message_event(message, event_name, **extra)
    conversation = message.conversation
    widget_tokens, client_tokens = split_contact_tokens(message_contact_inboxes(conversation, message))
    data = message.push_event_data.merge(extra)

    broadcast(conversation.account, inbox_user_tokens(conversation), event_name, data,
              widget: { tokens: widget_tokens, data: message.widget_push_event_data(data) })
    broadcast_to_client_sessions(conversation.account, client_tokens, event_name, Conversations::EventDataPresenter.contact_message(data))
  end

  # Built once and shared: `push_event_data` is several queries deep, and the contact's copy is a
  # subset of the agents', never a fresher read. `metadata` is per-event (eg. `event_metadata`)
  # and survives the contact's narrowing.
  def broadcast_conversation_event(conversation, event_name, metadata = {})
    widget_tokens, client_tokens = split_contact_tokens(session_contact_inboxes(conversation.contact_inbox))
    # The web widget has no handler for conversation.updated
    widget_tokens = [] if event_name == CONVERSATION_UPDATED
    payload = conversation.push_event_data.merge(metadata)

    broadcast(conversation.account, inbox_user_tokens(conversation), event_name, payload,
              widget: { tokens: widget_tokens, data: conversation.widget_push_event_data })
    broadcast_to_client_sessions(conversation.account, client_tokens, event_name, Conversations::EventDataPresenter.contact_slice(payload))
  end

  # Upstream hands Client API sessions the agents' payload. The fork gives them the contact's
  # copy, narrowed by the caller: a Client API session is the contact's own browser as much as
  # the widget is, and the agents' conversation payload carries labels, custom attributes, the
  # assignee and the last private note. `performer` is skipped for the same reason: it is the
  # acting agent's name and status. ContactSessionBroadcastJob narrows the conversation it
  # refreshes the same way.
  def broadcast_to_client_sessions(account, client_tokens, event_name, data)
    return if client_tokens.blank?

    ::ContactSessionBroadcastJob.perform_later(client_tokens.uniq, event_name, data.merge(account_id: account.id))
  end

  # Client API sessions get the contact's copy of the conversation, like every other conversation
  # event that reaches them (see #broadcast_to_client_sessions). `user` stays: it is what renders
  # "agent is typing".
  def broadcast_typing_event(event, event_name)
    conversation = event.data[:conversation]
    user = event.data[:user]
    widget_tokens, client_tokens = split_contact_tokens(typing_contact_inboxes(conversation, user))
    data = { conversation: conversation.push_event_data, user: user.push_event_data, is_private: event.data[:is_private] || false }

    broadcast(conversation.account, typing_user_tokens(conversation, user), event_name, data,
              widget: { tokens: widget_tokens, data: data.merge(conversation: conversation.widget_push_event_data) })
    broadcast_to_client_sessions(conversation.account, client_tokens, event_name, data.merge(conversation: conversation.contact_push_event_data))
  end

  # Web widget sessions get the widget payload, Client API sessions the contact's copy.
  def split_contact_tokens(contact_inboxes)
    widget_inboxes, client_inboxes = contact_inboxes.partition { |contact_inbox| contact_inbox.inbox.web_widget? }
    [widget_inboxes.filter_map(&:pubsub_token), client_inboxes.filter_map(&:pubsub_token)]
  end

  def inbox_user_tokens(conversation)
    user_tokens(conversation.account, conversation.inbox.members)
  end

  # Whoever is typing does not get their own typing event
  def typing_user_tokens(conversation, user)
    tokens = inbox_user_tokens(conversation)
    user.respond_to?(:pubsub_token) ? tokens - [user.pubsub_token] : tokens
  end

  def typing_contact_inboxes(conversation, user)
    user.is_a?(Contact) ? [] : [conversation.contact_inbox]
  end

  def user_tokens(account, agents)
    agent_tokens = agents.pluck(:pubsub_token)
    admin_tokens = account.administrators.pluck(:pubsub_token)
    (agent_tokens + admin_tokens).uniq
  end

  def message_contact_inboxes(conversation, message)
    return [] if message.private? || message.activity? || conversation.contact_inbox.nil?

    session_contact_inboxes(conversation.contact_inbox)
  end

  # A verified session also reaches the contact's other verified sessions, in any inbox that still exists
  def session_contact_inboxes(contact_inbox)
    return [contact_inbox] unless contact_inbox.hmac_verified?

    contact_inbox.contact.contact_inboxes.where(hmac_verified: true).where.associated(:inbox).includes(:inbox).to_a
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

  # widget: { tokens:, data: } sends web widget sessions their payload in the same job
  def broadcast(account, tokens, event_name, data, widget: {})
    widget_tokens = widget[:tokens].to_a
    return if tokens.blank? && widget_tokens.blank?

    widget_options = {}
    widget_options = { widget_members: widget_tokens.uniq, widget_data: broadcast_payload(account, widget[:data]) } if widget_tokens.present?
    ::ActionCableBroadcastJob.perform_later(tokens.uniq, event_name, broadcast_payload(account, data), **widget_options)
  end

  def broadcast_payload(account, data)
    payload = data.merge(account_id: account.id)
    # So the frondend knows who performed the action.
    # Useful in cases like conversation assignment for generating a notification with assigner name.
    payload[:performer] = Current.user&.push_event_data if Current.user.present?
    payload
  end
end

ActionCableListener.prepend_mod_with('ActionCableListener')
