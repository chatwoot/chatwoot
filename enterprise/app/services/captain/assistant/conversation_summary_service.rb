class Captain::Assistant::ConversationSummaryService < Captain::Assistant::BaseAssistantService
  TOKEN_LIMIT = 16_000

  def initialize(conversation:)
    @conversation = conversation
    # Format conversation messages as text
    super(text: format_conversation_messages)
  end

  protected

  def agent_name
    'ConversationSummarizer'
  end

  def build_instructions
    Captain::PromptRenderer.render('summary', {})
  end

  def response_schema
    {
      type: 'object',
      properties: {
        customer_intent: {
          type: 'string',
          description: 'Brief description of what the customer wants (around 50 words)'
        },
        conversation_summary: {
          type: 'string',
          description: 'Summary of the conversation in approximately 200 words'
        },
        action_items: {
          type: 'array',
          description: 'List of action items committed to by the agent or left incomplete',
          items: {
            type: 'string'
          }
        },
        follow_up_items: {
          type: 'array',
          description: 'List of unresolved issues or outstanding questions',
          items: {
            type: 'string'
          }
        }
      },
      required: %w[customer_intent conversation_summary],
      additionalProperties: false
    }
  end

  def build_success_response(output)
    {
      success: true,
      summary: build_summary_markdown(output),
      structured_data: {
        customer_intent: extract_field(output, 'customer_intent'),
        conversation_summary: extract_field(output, 'conversation_summary'),
        action_items: extract_array_field(output, 'action_items'),
        follow_up_items: extract_array_field(output, 'follow_up_items')
      }
    }
  end

  private

  def format_conversation_messages
    messages = []
    character_count = 0

    @conversation.messages
                 .where(message_type: [:incoming, :outgoing])
                 .where(private: false)
                 .reorder('id desc')
                 .each do |message|
      break if character_count + message.content.length > TOKEN_LIMIT
      next unless message.content.present?

      messages.prepend(format_message(message))
      character_count += message.content.length
    end

    messages.join("\n")
  end

  def format_message(message)
    sender_type = message.incoming? ? 'Customer' : 'Agent'
    sender_name = message.sender&.name || 'Unknown'
    "#{sender_type} #{sender_name}: #{message.content}"
  end

  def extract_array_field(output, field_name)
    return [] unless output.is_a?(Hash)

    output[field_name.to_sym] || output[field_name.to_s] || []
  end

  def build_summary_markdown(output)
    return '' unless output.is_a?(Hash)

    sections = []

    # Customer Intent
    if (intent = extract_field(output, 'customer_intent')).present?
      sections << "**Customer Intent**\n\n#{intent}"
    end

    # Conversation Summary
    if (summary = extract_field(output, 'conversation_summary')).present?
      sections << "**Conversation Summary**\n\n#{summary}"
    end

    # Action Items
    action_items = extract_array_field(output, 'action_items')
    if action_items&.any?
      items_list = action_items.map { |item| "- #{item}" }.join("\n")
      sections << "**Action Items**\n\n#{items_list}"
    end

    # Follow-up Items
    follow_up_items = extract_array_field(output, 'follow_up_items')
    if follow_up_items&.any?
      items_list = follow_up_items.map { |item| "- #{item}" }.join("\n")
      sections << "**Follow-up Items**\n\n#{items_list}"
    end

    sections.join("\n\n")
  end
end
