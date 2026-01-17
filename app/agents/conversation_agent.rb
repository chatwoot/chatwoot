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

  reliability do
    fallback_models ['gpt-4.1-mini', 'claude-haiku-4-5']
  end

  param :message, required: true

  MAX_CONVERSATION_HISTORY = 20

  def system_prompt
    parts = []
    parts << base_instructions
    parts << custom_instructions_section
    parts << personality_section
    parts << greeting_instructions
    parts << catalog_instructions
    parts << language_section
    parts << conversation_context_info
    parts.compact.join("\n\n")
  end

  def user_prompt
    message
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
    available_tools = [KnowledgeLookupTool]
    available_tools << HandoffTool if current_assistant&.feature_handoff_enabled?
    available_tools << ResolveTool if current_assistant&.feature_resolve_enabled?
    available_tools << SnoozeTool if current_assistant&.feature_snooze_enabled?
    available_tools << LabelsTool if current_assistant&.feature_labels_enabled?
    available_tools << AssignTool if current_assistant&.feature_handoff_enabled?
    available_tools << PrivateNoteTool

    if catalog_access_enabled?
      available_tools << ProductDetailsTool
      available_tools << CreateCartTool
    end

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
    return nil if current_assistant&.language_instruction.blank?

    current_assistant.language_instruction
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

  def catalog_instructions
    return nil unless catalog_access_enabled?

    products_list = build_products_list

    <<~PROMPT
      ## Product Catalog & Shopping

      #{products_list}

      When customers ask about products or want to buy something:

      1. **Recommend Products**: Use the product information above to suggest relevant items
      2. **Get Details**: Use the product_details tool when customers want more info about a specific product
      3. **Create Cart**: When the customer wants to buy, use the create_cart tool with product IDs and quantities
      4. **Payment Link**: After creating a cart, a payment link is automatically sent to the customer

      **IMPORTANT - Handling Follow-up References:**
      When a customer says "it", "this one", "that product", "add to cart", or similar phrases without specifying which product:
      - Look at your previous messages in the conversation history
      - Find the product ID you mentioned most recently
      - Use that product ID for the cart or follow-up action
      - Do NOT ask "which product?" if you already discussed one

      Example flows:

      Flow 1 - Explicit reference:
      - Customer: "I want to buy coffee"
      - You: "Here's our Premium Coffee (ID: 5) - 45 SAR. Would you like to order?"
      - Customer: "I'll take 2"
      - You: Use create_cart with product_id: 5, quantity: 2

      Flow 2 - Implicit "it" reference:
      - Customer: "Tell me about product 123"
      - You: Use product_details tool, then describe "Product X (ID: 123) - 30 SAR..."
      - Customer: "Add it to my cart"
      - You: Use create_cart with product_id: 123 (from your previous message)

      Flow 3 - "Send link" request:
      - Customer: "I want the premium beans"
      - You: "Great choice! Premium Beans (ID: 7) - 50 SAR. Want me to create a cart?"
      - Customer: "Yes, send me the payment link"
      - You: Use create_cart with product_id: 7
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

  # ============================================
  # Helper Methods
  # ============================================

  def first_message?
    messages.empty?
  end

  def catalog_enabled?
    current_account&.catalog_settings&.enabled?
  end

  def catalog_access_enabled?
    catalog_enabled? && current_assistant&.feature_catalog_access_enabled?
  end

  def build_products_list
    products = current_account.products.limit(30)
    return 'No products available in the catalog yet.' if products.empty?

    currency = current_account.catalog_settings&.currency || 'SAR'

    lines = ["Available Products (#{currency}):"]
    products.each do |product|
      title = product.title_en.presence || product.title_ar
      price = format('%.2f', product.price)
      lines << "- #{title} (ID: #{product.id}) - #{price} #{currency}"
    end

    lines.join("\n")
  end

  def business_name
    current_assistant&.description.presence ||
      current_conversation&.inbox&.business_name.presence ||
      'our company'
  end
end
