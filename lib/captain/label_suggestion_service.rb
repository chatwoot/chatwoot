class Captain::LabelSuggestionService < Captain::BaseEditorService
  CACHEABLE_EVENTS = %w[label_suggestion].freeze

  def label_suggestion_message
    payload = label_suggestion_body
    return nil if payload.blank?

    response = make_api_call(payload)
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
    messages = conversation_messages(in_array_format: false, start_from: labels.length)

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
end
