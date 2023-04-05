# frozen_string_literal: true

module Events::Types
  ### Installation Events ###
  # account events
  ACCOUNT_CREATED = 'account.created'
  ACCOUNT_CACHE_INVALIDATED = 'account.cache_invalidated'

  #### Account Events ###
  # campaign events
  CAMPAIGN_TRIGGERED = 'campaign.triggered'

  # channel events
  WEBWIDGET_TRIGGERED = 'webwidget.triggered'

  # conversation events
  CONVERSATION_CREATED = 'conversation.created'
  CONVERSATION_UPDATED = 'conversation.updated'
  CONVERSATION_READ = 'conversation.read'
  CONVERSATION_BOT_HANDOFF = 'conversation.bot_handoff'
  # FIXME: deprecate the opened and resolved events in future in favor of status changed event.
  CONVERSATION_OPENED = 'conversation.opened'
  CONVERSATION_RESOLVED = 'conversation.resolved'

  CONVERSATION_STATUS_CHANGED = 'conversation.status_changed'
  CONVERSATION_CONTACT_CHANGED = 'conversation.contact_changed'
  ASSIGNEE_CHANGED = 'assignee.changed'
  TEAM_CHANGED = 'team.changed'
  CONVERSATION_TYPING_ON = 'conversation.typing_on'
  CONVERSATION_TYPING_OFF = 'conversation.typing_off'
  CONVERSATION_MENTIONED = 'conversation.mentioned'

  # message events
  MESSAGE_CREATED = 'message.created'
  FIRST_REPLY_CREATED = 'first.reply.created'
  MESSAGE_UPDATED = 'message.updated'

  # contact events
  CONTACT_CREATED = 'contact.created'
  CONTACT_UPDATED = 'contact.updated'
  CONTACT_MERGED = 'contact.merged'
  CONTACT_DELETED = 'contact.deleted'

  # notification events
  NOTIFICATION_CREATED = 'notification.created'

  # agent events
  AGENT_ADDED = 'agent.added'
  AGENT_REMOVED = 'agent.removed'
end
