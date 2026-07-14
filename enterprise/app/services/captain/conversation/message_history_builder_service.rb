class Captain::Conversation::MessageHistoryBuilderService
  RESOLUTION_MARKER = 'Conversation resolution marker at %<resolved_at>s: %<details>s'.freeze

  pattr_initialize [:conversation!]

  def perform
    conversation_messages_for_context.filter_map do |message|
      message_hash = message_hash_for_context(message)
      next if message_hash.blank?

      message_hash[:agent_name] = message.additional_attributes['agent_name'] if message.additional_attributes&.dig('agent_name').present?
      message_hash
    end
  end

  private

  def conversation_messages_for_context
    conversation.messages.where(private: false, message_type: [:incoming, :outgoing, :activity])
  end

  def message_hash_for_context(message)
    return activity_message_hash(message) if message.message_type == 'activity'

    {
      content: prepare_multimodal_message_content(message),
      role: determine_role(message)
    }
  end

  def activity_message_hash(message)
    activity = message.content_attributes.to_h['activity'].to_h
    return unless activity['type'] == 'conversation_status_changed' && activity['status'] == 'resolved'

    {
      content: format(RESOLUTION_MARKER, resolved_at: message.created_at.utc.iso8601, details: message.content),
      role: 'assistant'
    }
  end

  def determine_role(message)
    message.message_type == 'incoming' ? 'user' : 'assistant'
  end

  def prepare_multimodal_message_content(message)
    Captain::OpenAiMessageBuilderService.new(message: message).generate_content
  end
end
