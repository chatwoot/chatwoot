class Captain::ReplySuggestionService < Captain::BaseEditorService
  def reply_suggestion_message
    make_api_call(reply_suggestion_body)
  end

  private

  def reply_suggestion_body
    {
      model: GPT_MODEL,
      messages: [
        { role: 'system', content: prompt_from_file('reply') }
      ].concat(conversation_messages(in_array_format: true))
    }.to_json
  end

  def conversation_messages(in_array_format: false)
    messages = init_messages_body(in_array_format)
    add_messages_until_token_limit(conversation, messages, in_array_format)
  end

  def init_messages_body(in_array_format)
    in_array_format ? [] : ''
  end

  def add_messages_until_token_limit(conversation, messages, in_array_format, start_from = 0)
    character_count = start_from
    conversation.messages
                .where(message_type: [:incoming, :outgoing])
                .where(private: false)
                .reorder('id desc')
                .each do |message|
      character_count, message_added = add_message_if_within_limit(character_count, message, messages, in_array_format)
      break unless message_added
    end
    messages
  end

  def add_message_if_within_limit(character_count, message, messages, in_array_format)
    content = message.content_for_llm
    if valid_message?(content, character_count)
      add_message_to_list(message, messages, in_array_format, content)
      character_count += content.length
      [character_count, true]
    else
      [character_count, false]
    end
  end

  def valid_message?(content, character_count)
    content.present? && character_count + content.length <= TOKEN_LIMIT
  end

  def add_message_to_list(message, messages, in_array_format, content)
    formatted_message = format_message(message, in_array_format, content)
    messages.prepend(formatted_message)
  end

  def format_message(message, in_array_format, content)
    in_array_format ? format_message_in_array(message, content) : format_message_in_string(message, content)
  end

  def format_message_in_array(message, content)
    { role: (message.incoming? ? 'user' : 'assistant'), content: content }
  end

  def format_message_in_string(message, content)
    sender_type = message.incoming? ? 'Customer' : 'Agent'
    "#{sender_type} #{message.sender&.name} : #{content}\n"
  end
end
