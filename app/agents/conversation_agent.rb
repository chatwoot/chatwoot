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
  include ResponsePolicies
  include CatalogSupport

  description 'Responds to customer messages using knowledge base and tools'

  model 'gpt-4.1'
  temperature 0.7
  version '1.0'
  timeout 60

  reliability do
    fallback_models ['gemini-2.5-flash', 'claude-haiku-4-5']
  end

  param :message, required: true

  MAX_CONVERSATION_HISTORY = 20

  def system_prompt
    (core_prompt_sections + policy_prompt_sections + content_prompt_sections).compact.join("\n\n")
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

  def section_header(title)
    separator = '=' * 24
    underline = '=' * title.length
    "#{separator}\n#{title}\n#{underline}"
  end

  def core_prompt_sections
    [base_instructions, priority_order_section, language_section,
     grounding_rules_section, operational_rules_section]
  end

  def policy_prompt_sections
    [disagreement_section, uncertainty_section, clarification_section,
     policy_boundaries_section, negative_capability_section, brevity_section,
     response_shape_section, human_communication_section,
     placeholder_safety_section, channel_formatting_section]
  end

  def content_prompt_sections
    [custom_instructions_section, personality_section, catalog_instructions,
     macros_section, conversation_closing_section, risk_awareness_section,
     human_handoff_section, conversation_context_info]
  end

  def base_instructions
    <<~PROMPT
      You are a customer support assistant for #{business_name}.

      Your responsibility is to assist customers clearly, accurately, and efficiently using only approved and verified information.

      You operate inside a Chatwoot-style conversational support system.
    PROMPT
  end

  def priority_order_section
    <<~PROMPT
      #{section_header('PRIORITY ORDER (STRICT)')}

      1. LANGUAGE RULES
      2. GROUNDING RULES
      3. OPERATIONAL RULES
      4. BREVITY
      5. STYLE & PERSONALITY
    PROMPT
  end

  def custom_instructions_section
    return nil if current_assistant&.custom_instructions.blank?

    <<~PROMPT
      #{section_header('BUSINESS INSTRUCTIONS')}

      #{current_assistant.custom_instructions}
    PROMPT
  end

  def personality_section
    return nil unless current_assistant

    personality = Aloo::PersonalityBuilder.new(current_assistant).build
    greeting = greeting_instructions

    parts = []
    parts << section_header('COMMUNICATION STYLE')
    parts << ''
    parts << personality
    parts << greeting if greeting
    parts.compact.join("\n")
  end

  def language_section
    <<~PROMPT
      #{section_header('LANGUAGE RULES (HIGHEST PRIORITY)')}

      1. Detect the language of the user's LAST message
      2. Respond entirely in the SAME language
      3. If the user switches languages, switch immediately
      4. Do NOT mix languages in a single response
      5. Exceptions: brand names, product names, technical terms with no natural translation
      #{preferred_language_instruction}
    PROMPT
  end

  def preferred_language_instruction
    parts = []

    if current_assistant&.language.present? && current_assistant.language != 'en'
      parts << "6. If the user's language is ambiguous, default to #{current_assistant.language_name}"
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
      "* #{macro.id} | #{macro.name}: #{macro.description}"
    end.join("\n")

    <<~PROMPT
      #{section_header('MACROS / AUTOMATIONS')}

      * Trigger execute_macro ONLY when the user's intent is clear and unambiguous
      * Never trigger macros on partial or unclear requests
      * If intent is unclear, ask a short clarification question

      Available Macros:

      #{macro_list}
    PROMPT
  end
end
