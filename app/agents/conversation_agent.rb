# frozen_string_literal: true

# Responds to customer messages using knowledge base, memories, and tools
#
# Example:
#   Aloo::Current.account = account
#   Aloo::Current.assistant = assistant
#   Aloo::Current.conversation = conversation
#   Aloo::Current.contact = contact
#
#   result = ConversationAgent.call(
#     message: "What is your refund policy?",
#     conversation_history: "Customer: Hi\nAssistant: Hello!"
#   )
#
class ConversationAgent < ApplicationAgent
  model 'gemini-2.0-flash'
  temperature 0.7
  version '1.0'
  timeout 60

  param :message, required: true
  param :conversation_history

  def system_prompt
    parts = []
    parts << base_instructions
    parts << personality_prompt
    parts << language_instructions
    parts << knowledge_context
    parts << memory_context
    parts << conversation_context_info
    parts << handoff_history_context
    parts.compact.join("\n\n")
  end

  def user_prompt
    parts = []
    parts << conversation_history if conversation_history.present?
    parts << "## Current Message\nCustomer: #{message}"
    parts.join("\n\n")
  end

  def tools
    available_tools = [FaqLookupTool]
    available_tools << HandoffTool if current_assistant&.feature_handoff_enabled?
    available_tools << ResolveTool if current_assistant&.feature_resolve_enabled?
    available_tools << SnoozeTool if current_assistant&.feature_snooze_enabled?
    available_tools << LabelsTool if current_assistant&.feature_labels_enabled?
    available_tools << AssignTool if current_assistant&.feature_handoff_enabled?
    available_tools << PrivateNoteTool
    available_tools
  end

  private

  def base_instructions
    <<~PROMPT
      You are a helpful customer support assistant for #{business_name}.
      Your role is to help customers with their questions and issues.

      ## Guidelines
      - Be helpful, accurate, and concise
      - If you don't know something, admit it rather than making up information
      - Use the faq_lookup tool to search for relevant information before answering
      #{handoff_guideline}
      - Stay focused on helping the customer with their current issue

      ## Available Tools
      #{available_tools_description}

      ## Important
      - Never make up policies or information not in your knowledge base
      #{handoff_important_note}
      - Always be respectful and professional
    PROMPT
  end

  def available_tools_description
    tool_descriptions = ['- faq_lookup: Search the knowledge base for relevant information']
    if current_assistant&.feature_handoff_enabled?
      tool_descriptions << '- handoff: Transfer the conversation to a human agent when needed'
      tool_descriptions << '- assign: Assign the conversation to a specific team or agent'
    end
    if current_assistant&.feature_resolve_enabled?
      tool_descriptions << '- resolve: Mark the conversation as resolved when the issue is fully addressed'
    end
    tool_descriptions << '- snooze: Snooze the conversation until a specific time' if current_assistant&.feature_snooze_enabled?
    tool_descriptions << '- labels: Add, remove, or set labels on the conversation' if current_assistant&.feature_labels_enabled?
    tool_descriptions << '- private_note: Add private notes for agent reference'
    tool_descriptions.join("\n")
  end

  def handoff_guideline
    return '' unless current_assistant&.feature_handoff_enabled?

    "- If a customer's request is beyond your capabilities, use the handoff tool to transfer to a human agent"
  end

  def handoff_important_note
    return '' unless current_assistant&.feature_handoff_enabled?

    '- If a customer seems frustrated or asks for a human multiple times, initiate handoff'
  end

  def business_name
    current_assistant&.description.presence ||
      current_conversation&.inbox&.business_name.presence ||
      'our company'
  end

  def knowledge_context
    return nil unless current_assistant && current_account

    service = Aloo::VectorSearchService.new(
      assistant: current_assistant,
      account: current_account
    )
    context = service.search_for_context(message)
    context.present? ? "## Relevant Information\n#{context}" : nil
  rescue StandardError => e
    Rails.logger.error("[ConversationAgent] Knowledge search failed: #{e.message}")
    nil
  end

  def memory_context
    return nil unless current_assistant&.feature_memory_enabled? && current_account

    service = Aloo::MemorySearchService.new(
      assistant: current_assistant,
      account: current_account
    )
    context = service.search_for_context(message, contact: current_contact)
    context.present? ? "## Customer Context\n#{context}" : nil
  rescue StandardError => e
    Rails.logger.error("[ConversationAgent] Memory search failed: #{e.message}")
    nil
  end

  def conversation_context_info
    contact = current_contact
    inbox = current_inbox
    return nil unless contact || inbox

    parts = ['## Conversation Context']
    parts << "- Contact: #{contact.name}" if contact&.name.present?
    parts << "- Channel: #{inbox.channel_type}" if inbox
    parts.join("\n")
  end

  def handoff_history_context
    return nil unless current_assistant&.feature_handoff_enabled?

    cleared_at = current_conversation&.custom_attributes&.dig('aloo_handoff_cleared_at')
    return nil if cleared_at.blank?

    <<~PROMPT
      ## Previous Handoff Notice
      This conversation was previously handed off to a human agent. The human has addressed all prior issues and returned the conversation to you.

      **CRITICAL**: Do NOT initiate handoff based on messages from the conversation history. Previous handoff requests have been handled. Only trigger handoff if the CURRENT message (the one you are responding to now) contains a NEW, explicit request for a human agent.
    PROMPT
  end
end
