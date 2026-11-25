# frozen_string_literal: true

module Events::Types
  ### Installation Events ###
  # account events
  ACCOUNT_CREATED = 'account.created'
  ACCOUNT_CACHE_INVALIDATED = 'account.cache_invalidated'
  ACCOUNT_PRESENCE_UPDATED = 'account.presence_updated'

  #### Account Events ###
  # campaign events
  CAMPAIGN_TRIGGERED = 'campaign.triggered'

  # channel events
  WEBWIDGET_TRIGGERED = 'webwidget.triggered'
  PROVIDER_EVENT_RECEIVED = 'provider.event_received'

  # conversation events
  CONVERSATION_CREATED = 'conversation.created'
  CONVERSATION_UPDATED = 'conversation.updated'
  CONVERSATION_DELETED = 'conversation.deleted'
  CONVERSATION_READ = 'conversation.read'
  CONVERSATION_BOT_HANDOFF = 'conversation.bot_handoff'
  # FIXME: deprecate the opened and resolved events in future in favor of status changed event.
  CONVERSATION_OPENED = 'conversation.opened'
  CONVERSATION_RESOLVED = 'conversation.resolved'
  CAPTAIN_CONVERSATION_HANDED_OFF = 'captain.conversation.handed_off'
  CAPTAIN_CONVERSATION_RESOLVED = 'captain.conversation.resolved'
  CAPTAIN_RESPONSE_COMPLETED = 'captain.response.completed'
  CAPTAIN_RESPONSE_FAILED = 'captain.response.failed'

  CONVERSATION_STATUS_CHANGED = 'conversation.status_changed'
  CONVERSATION_CONTACT_CHANGED = 'conversation.contact_changed'
  CONVERSATION_UNREAD_COUNT_CHANGED = 'conversation.unread_count_changed'
  ASSIGNEE_CHANGED = 'assignee.changed'
  TEAM_CHANGED = 'team.changed'
  CONVERSATION_TYPING_ON = 'conversation.typing_on'
  CONVERSATION_RECORDING = 'conversation.recording'
  CONVERSATION_TYPING_OFF = 'conversation.typing_off'
  CONVERSATION_MENTIONED = 'conversation.mentioned'
  CONVERSATION_UNREAD = 'conversation.unread'
  CONVERSATION_PINNED = 'conversation.pinned'
  CONVERSATION_UNPINNED = 'conversation.unpinned'

  # message events
  MESSAGE_CREATED = 'message.created'
  FIRST_REPLY_CREATED = 'first.reply.created'
  REPLY_CREATED = 'reply.created'
  MESSAGE_UPDATED = 'message.updated'
  # The body of a message that was stored before it could be read arriving into the row it was stored
  # as. Not an update of an existing message: it is the first time anything can be asked about this
  # message's content. Only the automation listener answers it (fazer-ai/chatwoot#491).
  MESSAGE_RECOVERED = 'message.recovered'
  # The body of a stored message replaced by a new one the sender wrote in its place. A different
  # question from the two above: a creation and a recovery are both the first readable body a row ever
  # had, and an edit is somebody changing what was said. Announced from the row itself
  # (`Message#dispatch_update_event`), so every channel that edits in place is covered by one dispatch
  # (fazer-ai/chatwoot#648).
  MESSAGE_EDITED = 'message.edited'
  MESSAGES_READ = 'messages.read'

  # scheduled message events
  SCHEDULED_MESSAGE_CREATED = 'scheduled_message.created'
  SCHEDULED_MESSAGE_UPDATED = 'scheduled_message.updated'
  SCHEDULED_MESSAGE_DELETED = 'scheduled_message.deleted'

  # recurring scheduled message events
  RECURRING_SCHEDULED_MESSAGE_CREATED = 'recurring_scheduled_message.created'
  RECURRING_SCHEDULED_MESSAGE_UPDATED = 'recurring_scheduled_message.updated'
  RECURRING_SCHEDULED_MESSAGE_DELETED = 'recurring_scheduled_message.deleted'

  # contact events
  CONTACT_CREATED = 'contact.created'
  CONTACT_UPDATED = 'contact.updated'
  CONTACT_MERGED = 'contact.merged'
  CONTACT_DELETED = 'contact.deleted'
  CONTACT_GROUP_SYNCED = 'contact.group_synced'

  # contact events
  INBOX_CREATED = 'inbox.created'
  INBOX_UPDATED = 'inbox.updated'
  INBOX_PROVIDER_CONNECTION_UPDATED = 'inbox.provider_connection_updated'

  # notification events
  NOTIFICATION_CREATED = 'notification.created'
  NOTIFICATION_DELETED = 'notification.deleted'
  NOTIFICATION_UPDATED = 'notification.updated'

  # agent events
  AGENT_ADDED = 'agent.added'
  AGENT_REMOVED = 'agent.removed'

  # copilot events
  COPILOT_MESSAGE_CREATED = 'copilot.message.created'
  COPILOT_MESSAGE_UPDATED = 'copilot.message.updated'

  # internal chat events
  INTERNAL_CHAT_MESSAGE_CREATED = 'internal_chat.message.created'
  INTERNAL_CHAT_MESSAGE_UPDATED = 'internal_chat.message.updated'
  INTERNAL_CHAT_MESSAGE_DELETED = 'internal_chat.message.deleted'
  INTERNAL_CHAT_CHANNEL_UPDATED = 'internal_chat.channel.updated'
  INTERNAL_CHAT_TYPING_ON = 'internal_chat.typing_on'
  INTERNAL_CHAT_TYPING_OFF = 'internal_chat.typing_off'
  INTERNAL_CHAT_REACTION_CREATED = 'internal_chat.reaction.created'
  INTERNAL_CHAT_REACTION_DELETED = 'internal_chat.reaction.deleted'
  INTERNAL_CHAT_POLL_VOTED = 'internal_chat.poll.voted'
end
