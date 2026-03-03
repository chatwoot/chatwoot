# frozen_string_literal: true

# Executes the AI agent and posts the reply to the conversation.
# Enqueued by AiAgentListener when an incoming message hits an inbox with an active AI agent.
class AiAgentReplyJob < ApplicationJob
  queue_as :default

  retry_on Llm::Client::RateLimitError, wait: :polynomially_longer, attempts: 5
  retry_on Llm::Client::TimeoutError, wait: 10.seconds, attempts: 3
  discard_on ActiveRecord::RecordNotFound

  MAX_HISTORY_MESSAGES = 20

  def perform(message_id:, ai_agent_id:, account_id:)
    @message = Message.find(message_id)
    ai_agent = Saas::AiAgent.find(ai_agent_id)
    account = Account.find(account_id)
    conversation = @message.conversation

    return post_limit_reply(conversation, account) if account.respond_to?(:ai_usage_exceeded?) && account.ai_usage_exceeded?

    send_whatsapp_presence(@message, conversation)
    execute_agent(ai_agent, conversation, @message, account)
    remove_whatsapp_reaction(@message, conversation)
  rescue StandardError => e
    remove_whatsapp_reaction(@message, conversation) if @message && conversation
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
    executor = Agent::WorkflowExecutor.new(
      ai_agent: ai_agent,
      conversation: conversation,
      user_message: message.content,
      conversation_history: history
    )
    result = executor.run

    # Workflow executor handles reply posting via ReplyNode.
    # Record token usage from the run log.
    total_tokens = result.workflow_run&.total_tokens || 0
    record_usage(account, ai_agent, { 'total_tokens' => total_tokens, 'prompt_tokens' => 0, 'completion_tokens' => 0 }) if total_tokens.positive?
  end

  def execute_classic(ai_agent, conversation, message, history, account)
    executor = Agent::Executor.new(ai_agent: ai_agent, conversation: conversation)
    result = executor.execute(user_message: message.content, conversation_history: history)

    unless result.handed_off?
      conversation.messages.create!(
        content: result.reply,
        message_type: :outgoing,
        account_id: account.id,
        inbox_id: conversation.inbox_id,
        content_attributes: { ai_generated: true, ai_agent_id: ai_agent.id }
      )
    end

    record_usage(account, ai_agent, result.usage) if result.usage
  end

  def build_history(conversation)
    conversation.messages
                .where(message_type: [:incoming, :outgoing])
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

  # --- WhatsApp presence helpers ---
  # These provide a better UX by showing the AI is "thinking":
  # 1. Mark the incoming message as read (blue double-check)
  # 2. React with 👀 to signal the AI has seen the message

  def whatsapp_channel?(conversation)
    conversation.inbox&.channel_type == 'Channel::Whatsapp' &&
      conversation.inbox&.channel&.provider == 'whatsapp_cloud'
  end

  def contact_phone(conversation)
    conversation.contact&.phone_number&.delete('+')
  end

  def send_whatsapp_presence(message, conversation)
    return unless whatsapp_channel?(conversation)

    channel = conversation.inbox.channel
    phone = contact_phone(conversation)
    return if phone.blank?

    # Mark incoming message as read
    channel.mark_as_read(message.source_id) if message.source_id.present?

    # React with 👀 (eyes) to show the AI is processing the message
    channel.send_reaction(phone, message.source_id, '👀') if message.source_id.present?
  rescue StandardError => e
    Rails.logger.warn "[AI_AGENT] WhatsApp presence failed: #{e.message}"
  end

  def remove_whatsapp_reaction(message, conversation)
    return unless whatsapp_channel?(conversation)

    channel = conversation.inbox.channel
    phone = contact_phone(conversation)
    return if phone.blank? || message.source_id.blank?

    # Remove the 👀 reaction by sending an empty emoji
    channel.send_reaction(phone, message.source_id, '')
  rescue StandardError => e
    Rails.logger.warn "[AI_AGENT] WhatsApp remove reaction failed: #{e.message}"
  end
end
