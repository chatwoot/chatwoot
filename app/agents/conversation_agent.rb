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
  description 'Responds to customer messages using knowledge base and tools'

  model 'gemini-2.5-flash'
  temperature 0.7
  version '1.0'
  timeout 60

  fallback_models ['gpt-4.1-mini', 'claude-haiku-4-5']

  param :message, required: true

  def system_prompt
    context_builder.system_prompt
  end

  def user_prompt
    context_builder.user_prompt(message)
  end

  def messages
    context_builder.messages
  end

  def tools
    available_tools = [KnowledgeLookupTool]
    available_tools << HandoffTool if current_assistant&.feature_handoff_enabled?
    available_tools << ResolveTool if current_assistant&.feature_resolve_enabled?
    available_tools << SnoozeTool if current_assistant&.feature_snooze_enabled?
    available_tools << LabelsTool if current_assistant&.feature_labels_enabled?
    available_tools << AssignTool if current_assistant&.feature_handoff_enabled?
    available_tools << PrivateNoteTool

    # Catalog tools - require both account catalog and assistant feature enabled
    available_tools << ProductSearchTool if product_search_enabled?
    available_tools << CreateCartTool if create_cart_enabled?

    available_tools
  end

  private

  def context_builder
    @context_builder ||= Aloo::ConversationContextBuilder.new(
      assistant: current_assistant,
      conversation: current_conversation
    )
  end

  def catalog_enabled?
    current_account&.catalog_settings&.enabled?
  end

  def product_search_enabled?
    catalog_enabled? && current_assistant&.feature_product_search_enabled?
  end

  def create_cart_enabled?
    catalog_enabled? && current_assistant&.feature_create_cart_enabled?
  end
end
