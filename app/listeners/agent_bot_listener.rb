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
    bots = agent_bots_for(inbox, message.conversation)
    bots.each { |agent_bot| process_message_event(method_name, agent_bot, message, event) }

    process_reengagement_for_message(message, bots)
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

    enriched = payload.merge(agent_bot_config: {
                               assistant_config: agent_bot.assistant_config,
                               agent_behavior_config: agent_bot.agent_behavior_config,
                               has_openai_api_key: agent_bot.has_openai_api_key?,
                               has_google_api_key: agent_bot.has_google_api_key?,
                               has_pinecone_api_key: agent_bot.account&.pinecone_api_key.present?
                             })
    AgentBots::WebhookJob.perform_later(agent_bot.outgoing_url, enriched, :agent_bot_webhook, idempotency_key)
  end

  def generate_idempotency_key(event_name, resource)
    return SecureRandom.uuid unless resource.respond_to?(:id) && resource.respond_to?(:updated_at)

    Digest::SHA256.hexdigest("#{event_name}-#{resource.class.name}-#{resource.id}-#{resource.updated_at.to_i}")
  end

  # ─── Proactive reengagement ──────────────────────────────────────────

  def process_reengagement_for_message(message, bots)
    conversation = message.conversation

    if message.outgoing?
      handle_outgoing_for_reengagement(message, conversation, bots)
    elsif message.incoming?
      handle_incoming_for_reengagement(message, conversation)
    end
  end

  def handle_outgoing_for_reengagement(message, conversation, bots)
    bot = bots.first
    return unless bot
    return unless reengagement_enabled?(bot)
    return if sequence_active?(conversation)

    reengagement = conversation.conversation_reengagement

    # If there's an active reengagement and we're within debounce window,
    # this outgoing message is likely the bot's own reengagement reply — skip reset.
    return if reengagement&.status == 'active' && reengagement.within_debounce_window?

    config = bot.agent_behavior_config&.dig('proactive_reengagement') || {}
    attempts = config['attempts'] || []
    return if attempts.empty?

    if reengagement && !reengagement.excluded_from_reactivation?(reengagement.status)
      reengagement.reactivate!(trigger_started_at: message.created_at)
    elsif reengagement.nil?
      ConversationReengagement.create!(
        conversation: conversation,
        agent_bot: bot,
        status: 'active',
        current_attempt: 0,
        trigger_started_at: message.created_at,
        next_fire_at: message.created_at + delay_duration(attempts[0])
      )
    end
  end

  def handle_incoming_for_reengagement(message, conversation)
    reengagement = conversation.conversation_reengagement
    return unless reengagement&.status == 'active'

    phrases, case_insensitive = reengagement.stop_keywords
    if phrases.present?
      text   = case_insensitive ? message.content.to_s.downcase : message.content.to_s
      matched = phrases.find { |p| text.include?(case_insensitive ? p.downcase : p) }
      if matched
        reengagement.cancel!(reason: 'cancelled_keyword', extra_meta: { 'matched_keyword' => matched })
        return
      end
    end

    reengagement.cancel!(reason: 'cancelled_reply') if reengagement.stop_on_any_reply?
  end

  def reengagement_enabled?(bot)
    bot.agent_behavior_config&.dig('proactive_reengagement', 'enabled') == true &&
      bot.outgoing_url.present?
  end

  def sequence_active?(conversation)
    ConversationFollowUp.where(conversation_id: conversation.id, status: 'active').exists?
  end

  def delay_duration(attempt)
    value = attempt['delay_value'].to_i
    case attempt['delay_unit'].to_s
    when 'hours' then value.hours
    when 'days'  then value.days
    else value.minutes
    end
  end
end
