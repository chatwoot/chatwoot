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
    parts << greeting_instructions
    parts << catalog_instructions
    parts << language_instructions
    parts << conversation_context_info
    parts.compact.join("\n\n")
  end

  def user_prompt(message)
    message
  end

  def messages
    return [] unless @conversation

    recent_messages = @conversation.recent_messages_for_llm(limit: MAX_CONVERSATION_HISTORY)
    return [] if recent_messages.empty?

    recent_messages.map do |msg|
      role = msg.message_type == 'incoming' ? :user : :assistant
      { role: role, content: msg.content_for_llm }
    end
  end

  def first_message?
    messages.empty?
  end

  private

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

  def greeting_instructions
    return nil unless @assistant

    if first_message?
      greeting_prompt_for_first_message
    else
      'Do not greet the customer - the conversation has already started. Continue naturally from the conversation history.'
    end
  end

  def greeting_prompt_for_first_message
    case @assistant.greeting_style
    when 'warm'
      'Start with a warm, friendly greeting to welcome the customer.'
    when 'direct'
      "Skip any greeting and address the customer's needs directly."
    when 'custom'
      if @assistant.custom_greeting.present?
        "Start by saying: \"#{@assistant.custom_greeting}\""
      else
        'Start with a brief greeting.'
      end
    else
      'Start with a brief greeting.'
    end
  end

  def catalog_instructions
    return nil unless catalog_enabled?

    products_list = build_products_list

    <<~PROMPT
      ## Product Catalog & Shopping

      #{products_list}

      When customers ask about products or want to buy something:

      1. **Recommend Products**: Use the product information above to suggest relevant items
      2. **Search if Needed**: Use the product_search tool for specific queries not covered above
      3. **Create Cart**: When the customer wants to buy, use the create_cart tool with product IDs and quantities
      4. **Payment Link**: After creating a cart, a payment link is automatically sent to the customer

      Example flow:
      - Customer: "I want to buy coffee"
      - You: Recommend matching products from the catalog with prices
      - Customer: "I'll take 2 of the premium beans"
      - You: Create cart with product_id and quantity 2, confirm the payment link was sent
    PROMPT
  end

  def catalog_enabled?
    return false unless @assistant

    account = @assistant.account
    account&.catalog_settings&.enabled? &&
      (@assistant.feature_product_search_enabled? || @assistant.feature_create_cart_enabled?)
  end

  def build_products_list
    account = @assistant.account
    products = account.products.limit(30)
    return 'No products available in the catalog yet.' if products.empty?

    currency = account.catalog_settings&.currency || 'SAR'

    lines = ["Available Products (#{currency}):"]
    products.each do |product|
      title = product.title_en.presence || product.title_ar
      price = format('%.2f', product.price)
      lines << "- #{title} (ID: #{product.id}) - #{price} #{currency}"
    end

    lines.join("\n")
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
