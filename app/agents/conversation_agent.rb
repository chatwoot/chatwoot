# frozen_string_literal: true

# Agent responsible for responding to customer messages
# Uses knowledge base, memories, and tools to generate helpful responses
#
# Usage:
#   agent = ConversationAgent.new(
#     account: account,
#     assistant: assistant,
#     conversation: conversation,
#     contact: contact
#   )
#   response = agent.call(message: "What is your refund policy?")
#
class ConversationAgent < ApplicationAgent
  MAX_CONVERSATION_HISTORY = 20

  def initialize(account:, assistant:, conversation:, contact: nil, message: nil)
    super(account: account, assistant: assistant, conversation: conversation, contact: contact)
    @message = message
    @message_content = extract_message_content(message)
  end

  # Generate a response to the customer message
  # @param message [String] Optional message override (uses @message_content if not provided)
  # @return [Hash] Response with content, metadata, and any actions taken
  def call(message: nil)
    message_text = message || @message_content
    return empty_response if message_text.blank?

    # Check if handoff is active (bot should not respond)
    return handoff_active_response if handoff_active?

    # Build context
    context = gather_context(message_text)
    conversation_history = build_conversation_history

    # Build the full prompt
    user_prompt = build_user_prompt(message_text, context, conversation_history)
    system_prompt = build_system_prompt

    # Execute with tools
    chat = build_chat(tools: available_tools)
    response = execute_with_tracing(chat, user_prompt, system: system_prompt)

    # Track token usage
    track_conversation_context(response)

    # Check if handoff was triggered
    handoff_triggered = check_handoff_triggered(response)

    {
      success: true,
      content: response.content,
      handoff_triggered: handoff_triggered,
      input_tokens: response.input_tokens,
      output_tokens: response.output_tokens,
      tool_calls: response.tool_calls&.map(&:name) || []
    }
  rescue RubyLLM::Error => e
    handle_llm_error(e)
  end

  protected

  def base_system_prompt
    <<~PROMPT
      You are a helpful customer support assistant for #{business_name}.
      Your role is to help customers with their questions and issues.

      ## Guidelines
      - Be helpful, accurate, and concise
      - If you don't know something, admit it rather than making up information
      - Use the faq_lookup tool to search for relevant information before answering
      - If a customer's request is beyond your capabilities, use the handoff tool to transfer to a human agent
      - Stay focused on helping the customer with their current issue

      ## Available Tools
      - faq_lookup: Search the knowledge base for relevant information
      - handoff: Transfer the conversation to a human agent when needed

      ## Important
      - Never make up policies or information not in your knowledge base
      - If a customer seems frustrated or asks for a human multiple times, initiate handoff
      - Always be respectful and professional
    PROMPT
  end

  private

  def extract_message_content(message)
    return message if message.is_a?(String)
    return message.content if message.respond_to?(:content)

    nil
  end

  def available_tools
    [FaqLookupMcp, HandoffMcp]
  end

  def business_name
    assistant.business_context.presence || conversation.inbox.business_name.presence || 'our company'
  end

  def handoff_active?
    return false unless conversation

    conversation.custom_attributes&.dig('aloo_handoff_active') == true
  end

  def handoff_active_response
    {
      success: false,
      content: nil,
      handoff_triggered: false,
      skip_response: true,
      reason: 'Conversation handed off to human agent'
    }
  end

  def empty_response
    {
      success: false,
      content: nil,
      reason: 'No message content provided'
    }
  end

  def build_conversation_history
    return '' unless conversation

    recent_messages = conversation.messages
                                  .where(message_type: %i[incoming outgoing])
                                  .where(private: false)
                                  .order(created_at: :desc)
                                  .limit(MAX_CONVERSATION_HISTORY)
                                  .reverse

    return '' if recent_messages.empty?

    history = recent_messages.map do |msg|
      role = msg.message_type == 'incoming' ? 'Customer' : 'Assistant'
      "#{role}: #{msg.content}"
    end

    "## Conversation History\n#{history.join("\n\n")}"
  end

  def build_user_prompt(message, context, history)
    parts = []

    parts << history if history.present?
    parts << context if context.present?
    parts << "## Current Message\nCustomer: #{message}"

    parts.join("\n\n")
  end

  def track_conversation_context(response)
    return unless conversation && assistant

    context = Aloo::ConversationContext.find_or_create_by!(
      conversation: conversation,
      assistant: assistant
    ) do |ctx|
      ctx.context_data = {}
      ctx.tool_history = []
    end

    context.track_message!(
      input_tokens: response.input_tokens || 0,
      output_tokens: response.output_tokens || 0,
      cost: estimate_cost(response)
    )
  end

  def estimate_cost(response)
    return 0 unless response.input_tokens && response.output_tokens

    # Rough cost estimate (adjust based on actual model pricing)
    input_cost = response.input_tokens * 0.00015 / 1000
    output_cost = response.output_tokens * 0.0006 / 1000
    input_cost + output_cost
  end

  def check_handoff_triggered(response)
    return false unless response.tool_calls

    response.tool_calls.any? { |tc| tc.name == 'handoff' }
  end

  def handle_llm_error(error)
    Rails.logger.error("[ConversationAgent] LLM error: #{error.message}")

    {
      success: false,
      content: nil,
      error: error.message,
      fallback_message: generate_fallback_message
    }
  end

  def generate_fallback_message
    return nil unless assistant

    case assistant.language
    when 'ar'
      'عذرًا، واجهت مشكلة تقنية. يرجى المحاولة مرة أخرى أو طلب التحدث مع أحد ممثلينا.'
    else
      "I apologize, but I'm experiencing a technical issue. Please try again or ask to speak with a human agent."
    end
  end
end
