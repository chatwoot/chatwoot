# frozen_string_literal: true

# Executes the AI agent and posts the reply to the conversation.
# Enqueued by AiAgentListener when an incoming message hits an inbox with an active AI agent.
class AiAgentReplyJob < ApplicationJob
  queue_as :default

  MAX_HISTORY_MESSAGES = 20

  def perform(message_id:, ai_agent_id:, account_id:)
    message = Message.find(message_id)
    ai_agent = Saas::AiAgent.find(ai_agent_id)
    account = Account.find(account_id)
    conversation = message.conversation

    # Check usage limits
    return post_limit_reply(conversation, account) if account.respond_to?(:ai_usage_exceeded?) && account.ai_usage_exceeded?

    # Build conversation history
    history = build_history(conversation)

    # Execute the agent
    executor = Agent::Executor.new(ai_agent: ai_agent, conversation: conversation)
    result = executor.execute(user_message: message.content, conversation_history: history)

    # Post the reply unless handed off
    unless result.handed_off?
      conversation.messages.create!(
        content: result.reply,
        message_type: :outgoing,
        account_id: account.id,
        inbox_id: conversation.inbox_id,
        content_attributes: { ai_generated: true, ai_agent_id: ai_agent.id }
      )
    end

    # Record token usage
    record_usage(account, ai_agent, result.usage) if result.usage
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: Account.find_by(id: account_id)).capture_exception
  end

  private

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
end
