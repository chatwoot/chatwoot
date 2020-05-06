# frozen_string_literal: true

module Events::Types
  # account events
  ACCOUNT_CREATED = 'account.created'
  ACCOUNT_DESTROYED = 'account.destroyed'

  # channel events
  WEBWIDGET_TRIGGERED = 'webwidget.triggered'

  # conversation events
  CONVERSATION_CREATED = 'conversation.created'
  CONVERSATION_READ = 'conversation.read'
  CONVERSATION_OPENED = 'conversation.opened'
  CONVERSATION_RESOLVED = 'conversation.resolved'
  CONVERSATION_LOCK_TOGGLE = 'conversation.lock_toggle'
  ASSIGNEE_CHANGED = 'assignee.changed'
  CONVERSATION_TYPING_ON = 'conversation.typing_on'
  CONVERSATION_TYPING_OFF = 'conversation.typing_off'

  # message events
  MESSAGE_CREATED = 'message.created'
  FIRST_REPLY_CREATED = 'first.reply.created'
  MESSAGE_UPDATED = 'message.updated'

  # contact events
  CONTACT_CREATED = 'contact.created'
  CONTACT_UPDATED = 'contact.updated'

  # subscription events
  AGENT_ADDED = 'agent.added'
  AGENT_REMOVED = 'agent.removed'
  SUBSCRIPTION_CREATED = 'subscription.created'
  SUBSCRIPTION_REACTIVATED = 'subscription.reactivated'
  SUBSCRIPTION_DEACTIVATED = 'subscription.deactivated'
end
