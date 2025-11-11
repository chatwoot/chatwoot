class AgentBotListener < BaseListener
  def conversation_resolved(event)
    conversation = extract_conversation_and_account(event)[0]
    inbox = conversation.inbox
    agent_bot = agent_bot_for(inbox, conversation)
    return unless agent_bot

    event_name = __method__.to_s
    payload = conversation.webhook_data.merge(event: event_name)
    process_webhook_bot_event(agent_bot, payload)
  end

  def conversation_opened(event)
    conversation = extract_conversation_and_account(event)[0]
    inbox = conversation.inbox
    agent_bot = agent_bot_for(inbox, conversation)
    return unless agent_bot

    event_name = __method__.to_s
    payload = conversation.webhook_data.merge(event: event_name)
    process_webhook_bot_event(agent_bot, payload)
  end

  def message_created(event)
    message = extract_message_and_account(event)[0]
    inbox = message.inbox
    agent_bot = agent_bot_for(inbox, message.conversation)
    return unless agent_bot
    return unless message.webhook_sendable?

    method_name = __method__.to_s
    process_message_event(method_name, agent_bot, message, event)
  end

  def message_updated(event)
    message = extract_message_and_account(event)[0]
    inbox = message.inbox
    agent_bot = agent_bot_for(inbox, message.conversation)
    return unless agent_bot
    return unless message.webhook_sendable?

    method_name = __method__.to_s
    process_message_event(method_name, agent_bot, message, event)
  end

  def webwidget_triggered(event)
    contact_inbox = event.data[:contact_inbox]
    inbox = contact_inbox.inbox
    agent_bot = agent_bot_for(inbox)
    return unless agent_bot

    event_name = __method__.to_s
    payload = contact_inbox.webhook_data.merge(event: event_name)
    payload[:event_info] = event.data[:event_info]
    process_webhook_bot_event(agent_bot, payload)
  end

  private

  def agent_bot_for(inbox, conversation = nil)
    return conversation.assignee_agent_bot if conversation&.assignee_agent_bot.present?

    active_inbox_agent_bot(inbox)
  end

  def active_inbox_agent_bot(inbox)
    return unless inbox.agent_bot_inbox&.active?

    inbox.agent_bot
  end

  def process_message_event(method_name, agent_bot, message, _event)
    # Only webhook bots are supported
    payload = message.webhook_data.merge(event: method_name)
    process_webhook_bot_event(agent_bot, payload)
  end

  def process_webhook_bot_event(agent_bot, payload)
    return if agent_bot.outgoing_url.blank?

    AgentBots::WebhookJob.perform_later(agent_bot.outgoing_url, payload)
  end
end
