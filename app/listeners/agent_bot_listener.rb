class AgentBotListener < BaseListener
  def conversation_resolved(event)
    conversation = extract_conversation_and_account(event)[0]
    inbox = conversation.inbox
    return unless connected_agent_bot_exist?(inbox)

    event_name = __method__.to_s
    payload = conversation.webhook_data.merge(event: event_name)
    process_webhook_bot_event(inbox.agent_bot, payload)
  end

  def conversation_opened(event)
    conversation = extract_conversation_and_account(event)[0]
    inbox = conversation.inbox
    return unless connected_agent_bot_exist?(inbox)

    event_name = __method__.to_s
    payload = conversation.webhook_data.merge(event: event_name)
    process_webhook_bot_event(inbox.agent_bot, payload)
  end

  def message_created(event)
    message = extract_message_and_account(event)[0]
    inbox = message.inbox
    return unless connected_agent_bot_exist?(inbox)
    return unless message.webhook_sendable?

    method_name = __method__.to_s
    process_message_event(method_name, inbox.agent_bot, message, event)
  end

  def message_updated(event)
    message = extract_message_and_account(event)[0]
    inbox = message.inbox
    return unless connected_agent_bot_exist?(inbox)
    return unless message.webhook_sendable?

    method_name = __method__.to_s
    process_message_event(method_name, inbox.agent_bot, message, event)
  end

  def webwidget_triggered(event)
    contact_inbox = event.data[:contact_inbox]
    inbox = contact_inbox.inbox
    return unless connected_agent_bot_exist?(inbox)

    event_name = __method__.to_s
    payload = contact_inbox.webhook_data.merge(event: event_name)
    payload[:event_info] = event.data[:event_info]
    process_webhook_bot_event(inbox.agent_bot, payload)
  end

  private

  def connected_agent_bot_exist?(inbox)
    return if inbox.agent_bot_inbox.blank?
    return unless inbox.agent_bot_inbox.active?

    true
  end

  def process_message_event(method_name, agent_bot, message, event)
    case agent_bot.bot_type
    when 'webhook'
      payload = message.webhook_data.merge(event: method_name)
      process_webhook_bot_event(agent_bot, payload)
    when 'csml'
      process_csml_bot_event(event.name, agent_bot, message)
    end
  end

  def process_webhook_bot_event(agent_bot, payload)
    return if agent_bot.outgoing_url.blank?

    AgentBots::WebhookJob.perform_later(agent_bot.outgoing_url, payload)
  end

  def process_csml_bot_event(event, agent_bot, message)
    AgentBots::CsmlJob.perform_later(event, agent_bot, message)
  end
end
