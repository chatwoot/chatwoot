class Captain::ConversationCompletionService < Captain::BaseTaskService
  RESPONSE_SCHEMA = {
    type: 'object',
    properties: {
      complete: { type: 'boolean', description: 'Whether the conversation is complete and can be closed' },
      reason: { type: 'string', description: 'Brief explanation of why the conversation is complete or incomplete' }
    },
    required: %w[complete reason],
    additionalProperties: false
  }.freeze

  pattr_initialize [:account!, :conversation_display_id!]

  def perform
    content = format_messages_as_string
    return default_incomplete_response('No messages found') if content.blank?

    response = make_api_call(
      model: GPT_MODEL,
      messages: [
        { role: 'system', content: prompt_from_file('conversation_completion') },
        { role: 'user', content: content }
      ],
      schema: RESPONSE_SCHEMA
    )

    return default_incomplete_response(response[:error]) if response[:error].present?

    parse_response(response[:message])
  end

  private

  def format_messages_as_string
    messages = conversation_messages(start_from: 0)
    messages.map do |msg|
      sender_type = msg[:role] == 'user' ? 'Customer' : 'Assistant'
      "#{sender_type}: #{msg[:content]}"
    end.join("\n")
  end

  def parse_response(message)
    return default_incomplete_response('Invalid response format') unless message.is_a?(Hash)

    {
      complete: message['complete'] == true,
      reason: message['reason'] || 'No reason provided'
    }
  end

  def default_incomplete_response(reason)
    { complete: false, reason: reason }
  end

  def event_name
    'conversation_completion'
  end

  def build_follow_up_context?
    false
  end
end
