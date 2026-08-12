class Captain::Routines::Operations::Actions::ConversationSetStatus < Captain::Routines::Operations::Action
  configure(
    name: 'conversations.set_status', effect: 'internal_write',
    description: 'Change one conversation to open, pending, or resolved.',
    arguments: { conversation_id: 'conversation ID or reference', status: 'open, pending, or resolved' },
    required: %w[conversation_id status]
  )

  def execute(conversation_id:, status:)
    raise ArgumentError, "Invalid conversation status '#{status}'" unless status.to_s.in?(%w[open pending resolved])

    conversation = conversation!(conversation_id)
    conversation.update!(status: status)
    conversation_data(conversation.reload)
  end
end
