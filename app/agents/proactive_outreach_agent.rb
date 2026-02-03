# frozen_string_literal: true

# Generates proactive outreach messages for MoEngage events
#
# Example:
#   Aloo::Current.account = account
#   Aloo::Current.assistant = assistant
#   Aloo::Current.conversation = conversation
#
#   result = ProactiveOutreachAgent.call(event_context: {
#     event_name: 'cart_abandoned',
#     customer: { first_name: 'John' },
#     event_attributes: { product_name: 'Wireless Headphones', cart_value: '$199.99' }
#   })
#
class ProactiveOutreachAgent < ApplicationAgent
  include CatalogSupport

  description 'Generates personalized proactive outreach messages based on customer events'

  model 'gemini-2.5-flash'
  temperature 0.7
  version '1.0'
  timeout 60

  reliability do
    fallback_models ['gpt-4.1-mini', 'claude-haiku-4-5']
  end

  param :event_context, required: true

  def system_prompt
    parts = []
    parts << base_instructions
    parts << event_context_section
    parts << outreach_guidelines
    parts << personality_section
    parts << catalog_instructions
    parts << language_section
    parts.compact.join("\n\n")
  end

  def user_prompt
    build_outreach_prompt
  end

  def tools
    available_tools = [KnowledgeLookupTool]
    available_tools << ProductDetailsTool if catalog_access_enabled?
    available_tools
  end

  private

  def base_instructions
    <<~PROMPT
      You are a proactive customer engagement assistant for #{business_name}.

      Your job is to send a friendly, helpful first message to a customer based on a recent event (like an abandoned cart or browse activity). This is an outbound message - the customer has NOT messaged you yet.

      IMPORTANT: This is the FIRST message in the conversation. Be warm but not pushy. Your goal is to be helpful and start a conversation, not to hard-sell.
    PROMPT
  end

  def event_context_section
    <<~PROMPT
      ## Current Event Context
      #{format_event_context}
    PROMPT
  end

  def format_event_context
    lines = ["Event Type: #{event_name.to_s.titleize}"]
    lines << "Customer Name: #{customer_name}" if customer_name.present?
    lines.concat(event_attribute_lines)
    lines.concat(campaign_lines)
    lines.join("\n")
  end

  def event_attribute_lines
    attrs = event_context[:event_attributes] || {}
    [
      attrs[:product_name].present? ? "Product: #{attrs[:product_name]}" : nil,
      attrs[:cart_value].present? ? "Cart Value: #{attrs[:cart_value]}" : nil,
      attrs[:items_count].present? ? "Items Count: #{attrs[:items_count]}" : nil,
      attrs[:category].present? ? "Category: #{attrs[:category]}" : nil
    ].compact
  end

  def campaign_lines
    campaign = event_context[:campaign] || {}
    campaign[:name].present? ? ["Campaign: #{campaign[:name]}"] : []
  end

  def outreach_guidelines
    <<~PROMPT
      ## Message Guidelines
      - Start with a personalized greeting using the customer's name if available
      - Reference the specific event naturally (don't say "I see you abandoned your cart")
      - Be helpful and offer assistance, not pushy sales tactics
      - Keep it concise - 2-3 sentences max
      - End with an open question inviting conversation
      - DO NOT use placeholders like [Name] or [Product] - use real values or omit
      - DO NOT mention internal systems, events, or that you're an AI

      ## Tone Examples
      Good: "Hi John! I noticed the Wireless Headphones you were looking at are still available. Happy to help if you have any questions about them!"
      Bad: "Dear Customer, we noticed you abandoned your cart. Complete your purchase now for a discount!"

      ## Event-Specific Approaches
      - cart_abandoned: Focus on the specific product(s), offer help with questions
      - checkout_abandoned: Gently check if there were any issues, offer assistance
      - browse_abandoned: Mention the product category or item they viewed, offer recommendations
      - custom_event/campaign_triggered: Be helpful based on the campaign context
    PROMPT
  end

  def personality_section
    return nil unless current_assistant

    Aloo::PersonalityBuilder.new(current_assistant).build
  end

  def language_section
    <<~PROMPT
      ## Language Rules
      - Respond in the language most appropriate for the customer
      - If customer locale is available, use that language
      - Default to English if no language preference is known
      - Keep product names and brand names in their original form
      #{configured_dialect_instruction}
    PROMPT
  end

  def configured_dialect_instruction
    return '' if current_assistant&.language_instruction.blank?

    "\n- When responding in Arabic: #{current_assistant.language_instruction}"
  end

  def build_outreach_prompt
    event = event_name.to_s.titleize
    name = customer_name.presence || 'the customer'

    "Generate a proactive outreach message for #{name} based on a #{event} event. " \
      'Use the event context provided to personalize the message.'
  end

  def event_name
    event_context[:event_name] || 'campaign_triggered'
  end

  def customer_name
    customer = event_context[:customer] || {}
    customer[:first_name] || customer[:name]
  end

  def business_name
    current_assistant&.description.presence ||
      current_conversation&.inbox&.business_name.presence ||
      'our company'
  end
end
