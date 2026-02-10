# frozen_string_literal: true

# Responds to customer messages using knowledge base and tools
#
# Example:
#   Aloo::Current.account = account
#   Aloo::Current.assistant = assistant
#   Aloo::Current.conversation = conversation
#   Aloo::Current.contact = contact
#
#   result = ConversationAgent.call(message: "What is your refund policy?")
#
class ConversationAgent < ApplicationAgent
  include Guardrails
  include CatalogSupport

  description 'Responds to customer messages using knowledge base and tools'

  model 'gemini-2.5-flash'
  temperature 0.7
  version '1.0'
  timeout 60

  reliability do
    fallback_models ['gpt-4.1-mini', 'claude-haiku-4-5']
  end

  param :message, required: true

  MAX_CONVERSATION_HISTORY = 20

  def system_prompt
    parts = []
    parts << base_instructions
    parts << language_section
    parts << operational_rules_section
    parts << guardrails_section
    parts << custom_instructions_section
    parts << personality_section
    parts << greeting_instructions
    parts << catalog_instructions
    parts << macros_section
    parts << conversation_context_info
    parts.compact.join("\n\n")
  end

  def user_prompt
    message.is_a?(String) ? message : message.content
  end

  def messages
    return [] unless current_conversation

    recent_messages = current_conversation.recent_messages_for_llm(limit: MAX_CONVERSATION_HISTORY)
    return [] if recent_messages.empty?

    recent_messages.map do |msg|
      role = msg.message_type == 'incoming' ? :user : :assistant
      { role: role, content: msg.content_for_llm }
    end
  end

  def tools
    available_tools = [KnowledgeLookupTool, PrivateNoteTool]
    available_tools << HandoffTool if current_assistant&.feature_handoff_enabled?
    available_tools << ResolveTool if current_assistant&.feature_resolve_enabled?
    available_tools << SnoozeTool if current_assistant&.feature_snooze_enabled?
    available_tools << LabelsTool if current_assistant&.feature_labels_enabled?

    if catalog_access_enabled?
      available_tools << ProductDetailsTool
      available_tools << CreateCartTool
    end

    available_tools << ExecuteMacroTool if current_assistant&.feature_macros_enabled? && macros_available?

    available_tools
  end

  private

  # ============================================
  # System Prompt Sections
  # ============================================

  def base_instructions
    <<~PROMPT
      You are a customer support assistant for #{business_name}.

      Before answering any question, use the knowledge_lookup tool to find accurate information. Only share what you find - if no relevant information exists, let the customer know honestly rather than guessing.

      Keep responses helpful, accurate, and concise.
    PROMPT
  end

  def custom_instructions_section
    return nil if current_assistant&.custom_instructions.blank?

    <<~PROMPT
      ## Business Instructions
      #{current_assistant.custom_instructions}
    PROMPT
  end

  def personality_section
    return nil unless current_assistant

    Aloo::PersonalityBuilder.new(current_assistant).build
  end

  def language_section
    <<~PROMPT
      <LANGUAGE_RULES>
      ## LANGUAGE (HIGHEST PRIORITY — OVERRIDES ALL OTHER INSTRUCTIONS)
      1. DETECT the language of the user's LAST message
      2. RESPOND ENTIRELY in that same language — no exceptions
      3. If the user switches languages, switch with them immediately
      4. Do NOT mix languages within your response
      5. Only exception: brand names, product names, or technical terms with no natural translation
      #{preferred_language_instruction}
      </LANGUAGE_RULES>
    PROMPT
  end

  def preferred_language_instruction
    parts = []

    if current_assistant&.language.present? && current_assistant.language != 'en'
      parts << "6. Your preferred/default language is #{current_assistant.language_name} — use it when the user's language is ambiguous"
    end

    if current_assistant&.language == 'ar' && current_assistant&.dialect.present?
      dialect_prompt = Aloo::Assistant::ARABIC_DIALECTS.dig(current_assistant.dialect, :prompt)
      parts << "7. When responding in Arabic: #{dialect_prompt}" if dialect_prompt
    end

    return '' if parts.empty?

    "\n#{parts.join("\n")}"
  end

  def greeting_instructions
    return nil unless current_assistant

    if first_message?
      greeting_prompt_for_first_message
    else
      'Do not greet the customer - the conversation has already started. Continue naturally from the conversation history.'
    end
  end

  def greeting_prompt_for_first_message
    case current_assistant.greeting_style
    when 'warm'
      'Start with a warm, friendly greeting to welcome the customer.'
    when 'direct'
      "Skip any greeting and address the customer's needs directly."
    when 'custom'
      if current_assistant.custom_greeting.present?
        "Start by saying: \"#{current_assistant.custom_greeting}\""
      else
        'Start with a brief greeting.'
      end
    else
      'Start with a brief greeting.'
    end
  end

  def conversation_context_info
    return nil unless current_conversation

    contact = current_conversation.contact
    inbox = current_conversation.inbox

    parts = []
    parts << "Contact: #{contact.name}" if contact&.name.present?
    parts << "Channel: #{inbox.channel_type}" if inbox
    return nil if parts.empty?

    parts.join(' | ')
  end

  # ============================================
  # Helper Methods
  # ============================================

  def first_message?
    messages.empty?
  end

  def business_name
    current_assistant&.description.presence ||
      current_conversation&.inbox&.business_name.presence ||
      'our company'
  end

  def macros_available?
    available_macros.exists?
  end

  def available_macros
    current_account&.macros&.ai_available || Macro.none
  end

  def macros_section
    return nil unless current_assistant&.feature_macros_enabled? && macros_available?

    macro_list = available_macros.select(:id, :name, :description).map do |macro|
      "- ID: #{macro.id} | #{macro.name}: #{macro.description}"
    end.join("\n")

    <<~PROMPT
      ## Available Macros
      You can trigger these predefined workflows when appropriate using the execute_macro tool:
      #{macro_list}

      Only trigger a macro when it clearly matches the customer's needs.
    PROMPT
  end
end
