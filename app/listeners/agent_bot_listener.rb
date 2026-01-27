class AgentBotListener < BaseListener
  def conversation_resolved(event)
    conversation = extract_conversation_and_account(event)[0]
    inbox = conversation.inbox
    event_name = __method__.to_s
    payload = conversation.webhook_data.merge(event: event_name)
    agent_bots_for(inbox, conversation).each { |agent_bot| process_webhook_bot_event(agent_bot, payload) }
  end

  def conversation_opened(event)
    conversation = extract_conversation_and_account(event)[0]
    inbox = conversation.inbox
    event_name = __method__.to_s
    payload = conversation.webhook_data.merge(event: event_name)
    agent_bots_for(inbox, conversation).each { |agent_bot| process_webhook_bot_event(agent_bot, payload) }
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
    payload = contact_inbox.webhook_data.merge(event: event_name)
    payload[:event_info] = event.data[:event_info]
    agent_bots_for(inbox).each { |agent_bot| process_webhook_bot_event(agent_bot, payload) }
  end

  private

  def agent_bots_for(inbox, conversation = nil)
    bots = []
    bots << conversation.assignee_agent_bot if conversation&.assignee_agent_bot.present?
    inbox_bot = active_inbox_agent_bot(inbox)
    bots << inbox_bot if inbox_bot.present?
    bots.compact.uniq
  end

  def process_message_event(method_name, agent_bot, message, event)
    conversation = message.conversation
    case agent_bot.bot_type
    when 'stark'
      if message.outgoing? && message.sender.is_a?(User)
        disable_stark_for(conversation)
        return
      end

      return unless message.incoming?

      process_stark_bot_event(event.name, agent_bot, message, conversation)
    when 'webhook'
      payload = message.webhook_data.merge(event: method_name)
      process_webhook_bot_event(agent_bot, payload)
    end
  end

  def active_inbox_agent_bot(inbox)
    return unless inbox.agent_bot_inbox&.active?

    inbox.agent_bot
  end

  def process_stark_bot_event(event, agent_bot, message, conversation)
    return if agent_bot.outgoing_url.blank?
    return unless message.present? && conversation.present?

    message_type = conversation.additional_attributes['type']
    # Check if the message_type is 'feed_comment' or 'instagram_comment', and skip job execution if true
    return if message_type == 'feed_comments' || message_type == 'instagram_comments'

    AgentBots::StarkJob.perform_later(event, agent_bot, message)
  end

  def process_webhook_bot_event(agent_bot, payload)
    return if agent_bot.outgoing_url.blank?

    AgentBots::WebhookJob.perform_later(agent_bot.outgoing_url, payload)
  end

  def disable_stark_for(conversation)
    conversation.cancel_existing_follow_up_job
    config_value = InstallationConfig.find_by(name: 'STARK_DISABLE_DURATION_HOURS')&.value
    duration = (config_value || 24).to_i.hours
    conversation.update!(additional_attributes: conversation.additional_attributes.merge('stark_disabled_until' => duration.from_now.to_i))
  end
end
