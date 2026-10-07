class Mcp::Tools::ListConversations < Mcp::Tools::Base
  LAST_MESSAGE_LENGTH = 200

  tool_name 'list_conversations'
  description 'List customer conversations the user can access, newest activity first. Returns 25 per page with the latest message of each. ' \
              'Use get_conversation to read the full message history of one conversation.'
  scope 'conversations:read'
  annotations(read_only_hint: true, destructive_hint: false, open_world_hint: false)
  input_schema(
    properties: {
      status: { type: 'string', enum: %w[open resolved pending snoozed all], description: 'Defaults to open.' },
      assignee_type: { type: 'string', enum: %w[me unassigned assigned all],
                       description: 'me returns conversations assigned to the user. Defaults to all.' },
      inbox_id: { type: 'integer', description: 'Only conversations of this inbox.' },
      labels: { type: 'array', items: { type: 'string' }, description: 'Only conversations with any of these labels.' },
      query: { type: 'string', description: 'Only conversations with a message that contains this text. Ignores status.' },
      page: { type: 'integer', minimum: 1 }
    }
  )

  def self.perform(query: nil, **filters)
    result = ConversationFinder.new(Current.user, filters.merge(q: query).compact).perform

    respond(
      conversations: result[:conversations].map { |conversation| conversation_summary(conversation).merge(last_message: last_message(conversation)) },
      counts: result[:count]
    )
  end

  def self.last_message(conversation)
    conversation.messages.non_activity_messages.first&.content&.truncate(LAST_MESSAGE_LENGTH)
  end
  private_class_method :last_message
end
