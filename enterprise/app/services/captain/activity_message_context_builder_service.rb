class Captain::ActivityMessageContextBuilderService
  RESOLVED_CONTEXT = 'System activity: Conversation was marked resolved. This is a support episode boundary, ' \
                     'not a command to forget all earlier messages. Messages before this marker are ' \
                     'pre-resolution context. Use them only when the latest user message clearly continues ' \
                     'or refers back to that earlier issue.'.freeze

  pattr_initialize [:message!]

  def generate_content
    return unless resolved_status_activity?

    { content: RESOLVED_CONTEXT, role: 'assistant' }
  end

  private

  def resolved_status_activity?
    activity = message.content_attributes.to_h['activity'].to_h

    activity['type'] == 'conversation_status_changed' && activity['status'] == 'resolved'
  end
end
