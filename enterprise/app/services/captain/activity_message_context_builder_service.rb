class Captain::ActivityMessageContextBuilderService
  pattr_initialize [:message!]

  RESOLVED_CONTEXT = 'System activity: Conversation was marked resolved. Treat as a support episode boundary. ' \
                     'Use prior messages only if latest user message clearly refers back.'.freeze

  def generate_content
    return unless resolved_status_activity?

    { content: RESOLVED_CONTEXT, role: 'system' }
  end

  private

  def resolved_status_activity?
    activity = message.content_attributes.to_h['activity'].to_h

    activity['type'] == 'conversation_status_changed' && activity['status'] == 'resolved'
  end
end
