# frozen_string_literal: true

class Aloo::ConversationContextBuilder
  MAX_CONVERSATION_HISTORY = 20

  def initialize(assistant:, conversation: nil)
    @assistant = assistant
    @conversation = conversation
  end

  def system_prompt
    parts = []
    parts << base_instructions
    parts << personality_prompt
    parts << language_instructions
    parts << conversation_turn_context
    parts << conversation_context_info
    parts << handoff_history_context
    parts.compact.join("\n\n")
  end

  def user_prompt(message)
    parts = []
    parts << conversation_history if conversation_history.present?
    parts << "## Current Message\nCustomer: #{message}"
    parts.join("\n\n")
  end

  def first_message?
    conversation_history.blank?
  end

  def conversation_history
    @conversation_history ||= build_conversation_history
  end

  private

  def build_conversation_history
    return '' unless @conversation

    recent_messages = @conversation.recent_messages_for_llm(limit: MAX_CONVERSATION_HISTORY)
    return '' if recent_messages.empty?

    history = recent_messages.map do |msg|
      role = msg.message_type == 'incoming' ? 'Customer' : 'Assistant'
      "#{role}: #{msg.content_for_llm}"
    end

    "## Conversation History\n#{history.join("\n\n")}"
  end

  def base_instructions
    <<~PROMPT
      You are a helpful customer support assistant for #{business_name}.
      Your role is to help customers with their questions and issues.

      ## Critical Rules
      - BEFORE answering ANY question about products, policies, services, or procedures:
        1. ALWAYS use the knowledge_lookup tool first to search for relevant information
      - Do NOT answer questions from your general knowledge - only use information from tools
      - If tools return no relevant information, clearly state "I don't have information about that in my knowledge base" rather than guessing

      ## Guidelines
      - Be helpful, accurate, and concise
      - If you don't know something, admit it rather than making up information
      - Stay focused on helping the customer with their current issue

      ## Important
      - Never make up policies or information not in your knowledge base
      - Always be respectful and professional
    PROMPT
  end

  def personality_prompt
    return nil unless @assistant

    Aloo::PersonalityBuilder.new(@assistant).build
  end

  def language_instructions
    return nil if @assistant&.language_instruction.blank?

    "## Language Instructions\n#{@assistant.language_instruction}"
  end

  def conversation_turn_context
    if first_message?
      <<~PROMPT
        ## Conversation Status
        - This is the START of a new conversation
        - You may greet the customer appropriately based on your communication style
      PROMPT
    else
      <<~PROMPT
        ## Conversation Status
        - This is an ONGOING conversation
        - Do NOT greet the customer again - continue the discussion naturally
      PROMPT
    end
  end

  def conversation_context_info
    return nil unless @conversation

    contact = @conversation.contact
    inbox = @conversation.inbox

    parts = ['## Conversation Context']
    parts << "- Contact: #{contact.name}" if contact&.name.present?
    parts << "- Channel: #{inbox.channel_type}" if inbox
    parts.join("\n")
  end

  def handoff_history_context
    return nil unless @assistant&.feature_handoff_enabled?

    cleared_at = @conversation&.custom_attributes&.dig('aloo_handoff_cleared_at')
    return nil if cleared_at.blank?

    <<~PROMPT
      ## Previous Handoff Notice
      This conversation was previously handed off to a human agent. The human has addressed all prior issues and returned the conversation to you.

      **CRITICAL**: Do NOT initiate handoff based on messages from the conversation history. Previous handoff requests have been handled. Only trigger handoff if the CURRENT message (the one you are responding to now) contains a NEW, explicit request for a human agent.
    PROMPT
  end

  def business_name
    @assistant&.description.presence ||
      @conversation&.inbox&.business_name.presence ||
      'our company'
  end
end
