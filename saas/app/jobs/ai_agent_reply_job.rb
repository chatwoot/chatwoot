# frozen_string_literal: true

# Executes the AI agent and posts the reply to the conversation.
# Enqueued by AiAgentListener when an incoming message hits an inbox with an active AI agent.
class AiAgentReplyJob < ApplicationJob
  queue_as :default

  retry_on Llm::Client::RateLimitError, wait: :polynomially_longer, attempts: 5
  retry_on Llm::Client::TimeoutError, wait: 10.seconds, attempts: 3
  discard_on ActiveRecord::RecordNotFound

  MAX_HISTORY_MESSAGES = 20

  # Natural typing delay: simulates human typing speed.
  # MIN = minimum delay in seconds (always wait at least this long after LLM responds)
  # PER_CHAR = extra seconds per character in the reply
  # MAX = cap to avoid excessively long waits
  TYPING_DELAY_MIN = 1.0
  TYPING_DELAY_PER_CHAR = 0.03
  TYPING_DELAY_MAX = 8.0

  # Regex to extract an optional reaction directive from the LLM reply.
  # The LLM may prefix its reply with [REACT:😊] to react to the user's message.
  REACTION_PATTERN = /\A\s*\[REACT:([^\]]+)\]\s*/

  def perform(message_id:, ai_agent_id:, account_id:)
    @message = Message.find(message_id)
    ai_agent = Saas::AiAgent.find(ai_agent_id)
    account = Account.find(account_id)
    @conversation = @message.conversation

    return post_limit_reply(@conversation, account) if account.respond_to?(:ai_usage_exceeded?) && account.ai_usage_exceeded?

    # Mark as read + show typing indicator ("digitando..." bubble on WhatsApp)
    send_whatsapp_typing(@message)

    execute_agent(ai_agent, @conversation, @message, account)
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: Account.find_by(id: account_id)).capture_exception
    raise
  end

  private

  def execute_agent(ai_agent, conversation, message, account)
    history = build_history(conversation)
    send_initial_message(ai_agent, conversation, account) if history.size <= 1

    if ai_agent.has_workflow?
      execute_workflow(ai_agent, conversation, message, history, account)
    else
      execute_classic(ai_agent, conversation, message, history, account)
    end
  end

  def execute_workflow(ai_agent, conversation, message, history, account)
    user_content = message_content_for_llm(message)
    executor = Agent::WorkflowExecutor.new(
      ai_agent: ai_agent,
      conversation: conversation,
      user_message: user_content,
      conversation_history: history
    )
    result = executor.run

    # Workflow executor handles reply posting via ReplyNode.
    # Record token usage from the run log.
    total_tokens = result.workflow_run&.total_tokens || 0
    record_usage(account, ai_agent, { 'total_tokens' => total_tokens, 'prompt_tokens' => 0, 'completion_tokens' => 0 }) if total_tokens.positive?
  end

  def execute_classic(ai_agent, conversation, message, history, account)
    contact_context = build_contact_context(conversation)
    user_content = message_content_for_llm(message)
    executor = Agent::Executor.new(ai_agent: ai_agent, conversation: conversation)
    result = executor.execute(user_message: user_content, conversation_history: history, contact_context: contact_context)

    unless result.handed_off?
      reply_text, emoji = extract_reaction(result.reply)

      # Send the natural reaction on WhatsApp before replying
      send_whatsapp_reaction(message, emoji) if emoji.present?

      # Simulate natural typing delay so the reply doesn't appear instantly
      simulate_typing_delay(message, reply_text)

      conversation.messages.create!(
        content: reply_text,
        message_type: :outgoing,
        account_id: account.id,
        inbox_id: conversation.inbox_id,
        content_attributes: { ai_generated: true, ai_agent_id: ai_agent.id }
      )
    end

    record_usage(account, ai_agent, result.usage) if result.usage
  end

  def build_history(conversation)
    # Fetch recent messages excluding the current one (it's passed separately as user_message)
    conversation.messages
                .where(message_type: [:incoming, :outgoing])
                .where.not(id: @message.id)
                .order(created_at: :desc)
                .limit(MAX_HISTORY_MESSAGES)
                .reverse
                .map do |msg|
                  {
                    role: msg.incoming? ? 'user' : 'assistant',
                    content: msg.content
                  }
                end
  end

  def record_usage(account, ai_agent, usage)
    return unless defined?(Saas::AiUsageRecord)

    Saas::AiUsageRecord.record_usage!(
      account: account,
      provider: resolve_provider(ai_agent.model),
      model: ai_agent.model,
      tokens_input: usage['prompt_tokens'].to_i,
      tokens_output: usage['completion_tokens'].to_i,
      feature: 'ai_agent'
    )
  end

  def resolve_provider(model)
    LlmConstants::PROVIDER_PREFIXES.each do |provider, prefixes|
      return provider if prefixes.any? { |prefix| model.start_with?(prefix) }
    end
    'unknown'
  end

  def post_limit_reply(conversation, account)
    conversation.messages.create!(
      content: I18n.t('ai_agent.usage_limit_reached', default: 'AI usage limit reached. Please contact support.'),
      message_type: :outgoing,
      account_id: account.id,
      inbox_id: conversation.inbox_id,
      content_attributes: { ai_generated: true, system_message: true }
    )
  end

  def send_initial_message(ai_agent, conversation, account)
    builder = Agent::PromptSectionsBuilder.new(ai_agent)
    greeting = builder.initial_message
    return if greeting.blank?

    # Only send if this is the first interaction (no outgoing AI messages exist yet)
    return if conversation.messages.where(message_type: :outgoing).where("content_attributes->>'ai_generated' = 'true'").exists?

    conversation.messages.create!(
      content: greeting,
      message_type: :outgoing,
      account_id: account.id,
      inbox_id: conversation.inbox_id,
      content_attributes: { ai_generated: true, ai_agent_id: ai_agent.id, initial_message: true }
    )
  end

  # --- Contact context ---

  # Builds the text content to send to the LLM, handling media messages.
  # If the message is a pure media (audio/image/video with no text), we describe it.
  def message_content_for_llm(message)
    text = message.content.presence
    attachments = message.attachments

    if attachments.any?
      descriptions = attachments.map { |a| "[#{a.file_type} anexado]" }
      [text, *descriptions].compact.join("\n")
    else
      text || '[mensagem vazia]'
    end
  end

  def build_contact_context(conversation)
    contact = conversation.contact
    return nil unless contact

    parts = []
    parts << "Nome do cliente: #{contact.name}" if contact.name.present?
    parts << "Telefone: #{contact.phone_number}" if contact.phone_number.present?
    parts << "Email: #{contact.email}" if contact.email.present?
    parts.join("\n")
  end

  # --- WhatsApp helpers ---

  def whatsapp_channel?(conversation)
    conversation.inbox&.channel_type == 'Channel::Whatsapp' &&
      conversation.inbox&.channel&.provider == 'whatsapp_cloud'
  end

  def contact_phone(conversation)
    conversation.contact&.phone_number&.delete('+')
  end

  def send_whatsapp_typing(message)
    return unless whatsapp_channel?(message.conversation)
    return if message.source_id.blank?

    channel = message.conversation.inbox.channel
    # send_typing_indicator also marks the message as read (blue double-check)
    result = channel.send_typing_indicator(message.source_id)
    Rails.logger.info "[AI_AGENT] Typing indicator sent for message #{message.id} (source_id=#{message.source_id}): #{result}"
  rescue StandardError => e
    Rails.logger.warn "[AI_AGENT] WhatsApp typing indicator failed: #{e.class} — #{e.message}"
  end

  # Calculates and applies a natural typing delay based on reply length.
  # Also re-sends the typing indicator right before the delay so the user
  # still sees "digitando..." even if the LLM call took > 25s.
  def simulate_typing_delay(message, reply_text)
    return unless whatsapp_channel?(message.conversation)
    return if reply_text.blank?

    delay = [TYPING_DELAY_MIN + (reply_text.length * TYPING_DELAY_PER_CHAR), TYPING_DELAY_MAX].min
    Rails.logger.info "[AI_AGENT] Typing delay: #{delay.round(1)}s for #{reply_text.length} chars"

    # Re-send typing indicator so it's fresh (the previous one may have expired)
    send_whatsapp_typing(message)

    sleep(delay)
  rescue StandardError => e
    Rails.logger.warn "[AI_AGENT] Typing delay failed: #{e.message}"
  end

  def send_whatsapp_reaction(message, emoji)
    return unless whatsapp_channel?(message.conversation)

    channel = message.conversation.inbox.channel
    phone = contact_phone(message.conversation)
    return if phone.blank? || message.source_id.blank?

    channel.send_reaction(phone, message.source_id, emoji)
  rescue StandardError => e
    Rails.logger.warn "[AI_AGENT] WhatsApp reaction failed: #{e.message}"
  end

  # Extracts optional [REACT:emoji] prefix from the LLM reply.
  # Returns [clean_reply, emoji_or_nil].
  def extract_reaction(reply)
    return [reply, nil] if reply.blank?

    match = reply.match(REACTION_PATTERN)
    return [reply, nil] unless match

    emoji = match[1].strip
    clean_reply = reply.sub(REACTION_PATTERN, '').strip
    [clean_reply, emoji]
  end
end
