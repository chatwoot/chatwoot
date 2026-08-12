class Captain::Routines::Operations::Actions::ConversationAddPrivateNote < Captain::Routines::Operations::Action
  configure(
    name: 'conversations.add_private_note', effect: 'internal_write',
    description: 'Add an internal note to one conversation.',
    arguments: { conversation_id: 'conversation ID or reference', content: 'literal note content or rich_message reference' },
    required: %w[conversation_id content]
  )

  def execute(conversation_id:, content:)
    create_message(conversation!(conversation_id), content, private: true)
  end
end
