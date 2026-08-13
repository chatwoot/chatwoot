class Captain::Routines::Operations::Actions::ConversationSnooze < Captain::Routines::Operations::Action
  configure(
    name: 'conversations.snooze', effect: 'internal_write',
    description: 'Snooze one conversation until a specified time.',
    arguments: { conversation_id: 'conversation ID or reference', until: 'absolute or relative date and time' },
    required: %w[conversation_id until]
  )

  def execute(conversation_id:, **arguments)
    conversation = conversation!(conversation_id)
    conversation.update!(status: :snoozed, snoozed_until: timestamp!(arguments.fetch(:until)))
    conversation_data(conversation.reload)
  end
end
