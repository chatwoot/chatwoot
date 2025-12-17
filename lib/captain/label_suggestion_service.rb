class Captain::LabelSuggestionService < Captain::BaseEditorService
  CACHEABLE_EVENTS = %w[label_suggestion].freeze

  def label_suggestion_message
    content = labels_with_messages
    return nil if content.blank?

    response = make_api_call(
      model: GPT_MODEL, # TODO: Use separate model for label suggestion
      messages: [
        { role: 'system', content: prompt_from_file('label_suggestion') },
        { role: 'user', content: content }
      ]
    )
    return response if response[:error].present?

    # LLMs are not deterministic - sometimes response includes "Labels:" prefix
    # TODO: Fix with better prompt
    { message: response[:message] ? response[:message].gsub(/^(label|labels):/i, '') : '' }
  end

  private

  def labels_with_messages
    return nil unless valid_conversation?(conversation)

    labels = account.labels.pluck(:title).join(', ')
    messages = format_messages_as_string(start_from: labels.length)

    return nil if messages.blank? || labels.blank?

    "Messages:\n#{messages}\nLabels:\n#{labels}"
  end

  def format_messages_as_string(start_from: 0)
    messages = conversation_messages(start_from: start_from)
    messages.map do |msg|
      sender_type = msg[:role] == 'user' ? 'Customer' : 'Agent'
      "#{sender_type}: #{msg[:content]}\n"
    end.join
  end

  def valid_conversation?(conversation)
    return false if conversation.nil?
    return false if conversation.messages.incoming.count < 3
    return false if conversation.messages.count > 100
    return false if conversation.messages.count > 20 && !conversation.messages.last.incoming?

    true
  end
end
