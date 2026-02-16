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
  include PromptFormatting
  include Guardrails
  include ResponsePolicies
  include CatalogSupport
  include CalendlySupport
  include LanguageSupport
  include PersonalitySupport
  include MacroSupport

  description 'Responds to customer messages using knowledge base and tools'

  model 'gpt-4.1'
  temperature 0.7
  timeout 60

  on_failure do
    fallback to: ['gemini-2.5-flash', 'claude-haiku-4-5']
  end

  param :message, required: true

  MAX_CONVERSATION_HISTORY = 20

  # Declarative: feature flag → tool class
  FEATURE_TOOLS = [
    [:feature_handoff_enabled?, HandoffTool],
    [:feature_resolve_enabled?, ResolveTool],
    [:feature_snooze_enabled?,  SnoozeTool],
    [:feature_labels_enabled?,  LabelsTool]
  ].freeze

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
    available_tools.concat(feature_gated_tools)
    available_tools.concat(catalog_tools)
    available_tools << ExecuteMacroTool if current_assistant&.feature_macros_enabled? && macros_available?
    available_tools.concat(calendly_tools)
  end

  private

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

  def first_message?
    messages.empty?
  end

  def business_name
    current_assistant&.description.presence ||
      current_conversation&.inbox&.business_name.presence ||
      'our company'
  end

  def feature_gated_tools
    FEATURE_TOOLS.filter_map { |feature, tool| tool if current_assistant&.public_send(feature) }
  end
end
