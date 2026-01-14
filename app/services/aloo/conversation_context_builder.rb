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
    parts << custom_instructions_section
    parts << personality_prompt
    parts << language_instructions
    parts << conversation_context_info
    parts.compact.join("\n\n")
  end

  def user_prompt(message)
    parts = []
    parts << conversation_history if conversation_history.present?
    parts << "Customer: #{message}"
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

    history.join("\n\n")
  end

  def base_instructions
    <<~PROMPT
      You are a customer support assistant for #{business_name}.

      Before answering any question, use the knowledge_lookup tool to find accurate information. Only share what you find - if no relevant information exists, let the customer know honestly rather than guessing.

      Keep responses helpful, accurate, and concise.
    PROMPT
  end

  def custom_instructions_section
    return nil if @assistant&.custom_instructions.blank?

    <<~PROMPT
      ## Business Instructions
      #{@assistant.custom_instructions}
    PROMPT
  end

  def personality_prompt
    return nil unless @assistant

    Aloo::PersonalityBuilder.new(@assistant).build
  end

  def language_instructions
    return nil if @assistant&.language_instruction.blank?

    @assistant.language_instruction
  end

  def conversation_context_info
    return nil unless @conversation

    contact = @conversation.contact
    inbox = @conversation.inbox

    parts = []
    parts << "Contact: #{contact.name}" if contact&.name.present?
    parts << "Channel: #{inbox.channel_type}" if inbox
    return nil if parts.empty?

    parts.join(' | ')
  end

  def business_name
    @assistant&.description.presence ||
      @conversation&.inbox&.business_name.presence ||
      'our company'
  end
end
