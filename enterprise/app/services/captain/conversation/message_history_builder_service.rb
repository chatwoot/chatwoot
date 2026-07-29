class Captain::Conversation::MessageHistoryBuilderService
  RESOLUTION_MARKER = '<conversation_boundary status="resolved" />'.freeze
  RESOLVED_CITATION_PATTERN = /\[\[\d+\]\([^\n]*?\)\]/

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
    conversation.messages
                .where(private: false, message_type: [:incoming, :outgoing, :activity])
                .reorder(created_at: :asc, id: :asc)
  end

  def message_hash_for_context(message)
    return activity_message_hash(message) if message.message_type == 'activity'

    content = prepare_multimodal_message_content(message)
    return if content.blank?

    {
      content: content,
      role: determine_role(message)
    }
  end

  def activity_message_hash(message)
    activity = message.content_attributes.to_h['activity'].to_h
    return unless activity['type'] == 'conversation_status_changed' && activity['status'] == 'resolved'

    {
      content: RESOLUTION_MARKER,
      role: 'assistant'
    }
  end

  def determine_role(message)
    message.message_type == 'incoming' ? 'user' : 'assistant'
  end

  def prepare_multimodal_message_content(message)
    content = Captain::OpenAiMessageBuilderService.new(message: message).generate_content
    return content unless message.outgoing? && message.sender_type == 'Captain::Assistant'

    remove_resolved_citations(content)
  end

  def remove_resolved_citations(content)
    return content.gsub(RESOLVED_CITATION_PATTERN, '').presence if content.is_a?(String)

    content.filter_map do |part|
      next part unless part[:type] == 'text'

      text = part[:text].gsub(RESOLVED_CITATION_PATTERN, '')
      part.merge(text: text) if text.present?
    end.presence
  end
end
