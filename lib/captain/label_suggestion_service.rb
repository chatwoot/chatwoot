class Captain::LabelSuggestionService < Captain::BaseEditorService
  CACHEABLE_EVENTS = %w[label_suggestion].freeze

  def label_suggestion_message
    payload = label_suggestion_body
    return nil if payload.blank?

    response = make_api_call(label_suggestion_body)
    return response if response[:error].present?

    # LLMs are not deterministic - sometimes response includes "Labels:" prefix
    # TODO: Fix with better prompt
    { message: response[:message] ? response[:message].gsub(/^(label|labels):/i, '') : '' }
  end

  private

  def label_suggestion_body
    # TODO: Enable based on separate model and settings source
    # Future: Different model for label suggestion
    # Future: Settings-based feature gating
    # For now: Enabled by default when API key available

    content = labels_with_messages
    return value_from_cache if content.blank?

    {
      model: GPT_MODEL, # TODO: Use separate model for label suggestion
      messages: [
        {
          role: 'system',
          content: prompt_from_file('label_suggestion')
        },
        { role: 'user', content: content }
      ]
    }
  end

  def labels_with_messages
    return nil unless valid_conversation?(conversation)

    labels = account.labels.pluck(:title).join(', ')
    character_count = labels.length

    messages = init_messages_body(false)
    add_messages_until_token_limit(conversation, messages, false, character_count)

    return nil if messages.blank? || labels.blank?

    "Messages:\n#{messages}\nLabels:\n#{labels}"
  end

  def valid_conversation?(conversation)
    return false if conversation.nil?
    return false if conversation.messages.incoming.count < 3
    return false if conversation.messages.count > 100
    return false if conversation.messages.count > 20 && !conversation.messages.last.incoming?

    true
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
