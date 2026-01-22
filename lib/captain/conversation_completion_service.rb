class Captain::ConversationCompletionService < Captain::BaseTaskService
  pattr_initialize [:account!, :conversation_display_id!]

  def perform
    content = format_messages_as_string
    return default_incomplete_response('No messages found') if content.blank?

    response = make_api_call(
      model: GPT_MODEL,
      messages: [
        { role: 'system', content: prompt_from_file('conversation_completion') },
        { role: 'user', content: content }
      ]
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
    json = JSON.parse(message, symbolize_names: true)
    {
      complete: json[:complete] == true,
      reason: json[:reason] || 'No reason provided'
    }
  rescue JSON::ParserError
    default_incomplete_response('Failed to parse LLM response')
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
