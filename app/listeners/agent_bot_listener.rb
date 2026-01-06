class AgentBotListener < BaseListener
  def conversation_resolved(event)
    conversation = extract_conversation_and_account(event)[0]
    inbox = conversation.inbox
    event_name = __method__.to_s
    idempotency_key = generate_idempotency_key(event_name, conversation)
    payload = conversation.webhook_data.merge(event: event_name, idempotency_key: idempotency_key)
    agent_bots_for(inbox, conversation).each { |agent_bot| process_webhook_bot_event(agent_bot, payload, idempotency_key) }
  end

  def conversation_opened(event)
    conversation = extract_conversation_and_account(event)[0]
    inbox = conversation.inbox
    event_name = __method__.to_s
    idempotency_key = generate_idempotency_key(event_name, conversation)
    payload = conversation.webhook_data.merge(event: event_name, idempotency_key: idempotency_key)
    agent_bots_for(inbox, conversation).each { |agent_bot| process_webhook_bot_event(agent_bot, payload, idempotency_key) }
  end

  def message_created(event)
    message = extract_message_and_account(event)[0]
    inbox = message.inbox
    return unless message.webhook_sendable?

    method_name = __method__.to_s
    agent_bots_for(inbox, message.conversation).each { |agent_bot| process_message_event(method_name, agent_bot, message, event) }
  end

  def message_updated(event)
    message = extract_message_and_account(event)[0]
    inbox = message.inbox
    return unless message.webhook_sendable?

    method_name = __method__.to_s
    agent_bots_for(inbox, message.conversation).each { |agent_bot| process_message_event(method_name, agent_bot, message, event) }
  end

  def webwidget_triggered(event)
    contact_inbox = event.data[:contact_inbox]
    inbox = contact_inbox.inbox
    event_name = __method__.to_s
    idempotency_key = generate_idempotency_key(event_name, contact_inbox)
    payload = contact_inbox.webhook_data.merge(event: event_name, idempotency_key: idempotency_key)
    payload[:event_info] = event.data[:event_info]
    agent_bots_for(inbox).each { |agent_bot| process_webhook_bot_event(agent_bot, payload, idempotency_key) }
  end

  private

  def agent_bots_for(inbox, conversation = nil)
    bots = []
    bots << conversation.assignee_agent_bot if conversation&.assignee_agent_bot.present?
    inbox_bot = active_inbox_agent_bot(inbox)
    bots << inbox_bot if inbox_bot.present?
    bots.compact.uniq
  end

  def active_inbox_agent_bot(inbox)
    return unless inbox.agent_bot_inbox&.active?

    inbox.agent_bot
  end

  def process_message_event(method_name, agent_bot, message, _event)
    # Only webhook bots are supported
    idempotency_key = generate_idempotency_key(method_name, message)
    payload = message.webhook_data.merge(event: method_name, idempotency_key: idempotency_key)
    process_webhook_bot_event(agent_bot, payload, idempotency_key)
  end

  def process_webhook_bot_event(agent_bot, payload, idempotency_key)
    return if agent_bot.outgoing_url.blank?

    AgentBots::WebhookJob.perform_later(agent_bot.outgoing_url, payload, :agent_bot_webhook, idempotency_key)
  end

  def generate_idempotency_key(event_name, resource)
    return SecureRandom.uuid unless resource.respond_to?(:id) && resource.respond_to?(:updated_at)

    Digest::SHA256.hexdigest("#{event_name}-#{resource.class.name}-#{resource.id}-#{resource.updated_at.to_i}")
  end
end
