class Captain::Routines::Operations::Actions::ConversationSetPriority < Captain::Routines::Operations::Action
  configure(
    name: 'conversations.set_priority', effect: 'internal_write',
    description: 'Set the priority of one conversation.',
    arguments: { conversation_id: 'conversation ID or reference', priority: 'low, medium, high, or urgent' },
    required: %w[conversation_id priority]
  )

  def execute(conversation_id:, priority:)
    Conversation.priorities.fetch(priority.to_s)
    conversation = conversation!(conversation_id)
    conversation.update!(priority: priority)
    conversation_data(conversation.reload)
  end
end
