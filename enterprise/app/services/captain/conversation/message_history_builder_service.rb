class Captain::Conversation::MessageHistoryBuilderService
  pattr_initialize [:conversation!, :assistant!]

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
    messages = conversation.messages.where(private: false)
    messages = messages.where('created_at >= ?', conversation.last_resolved_at.change(usec: 0)) if since_last_resolution_boundary?
    messages.where(message_type: context_message_types)
  end

  def since_last_resolution_boundary?
    assistant.conversation_context_since_last_resolution? && conversation.last_resolved_at.present?
  end

  def context_message_types
    return [:incoming, :outgoing, :activity] if assistant.conversation_context_with_resolution_markers?

    [:incoming, :outgoing]
  end

  def message_hash_for_context(message)
    return activity_message_hash(message) if message.message_type == 'activity'

    {
      content: prepare_multimodal_message_content(message),
      role: determine_role(message)
    }
  end

  def activity_message_hash(message)
    Captain::ActivityMessageContextBuilderService.new(message: message).generate_content
  end

  def determine_role(message)
    message.message_type == 'incoming' ? 'user' : 'assistant'
  end

  def prepare_multimodal_message_content(message)
    Captain::OpenAiMessageBuilderService.new(message: message).generate_content
  end
end
