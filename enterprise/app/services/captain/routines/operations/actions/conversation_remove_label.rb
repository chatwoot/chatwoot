class Captain::Routines::Operations::Actions::ConversationRemoveLabel < Captain::Routines::Operations::Action
  configure(
    name: 'conversations.remove_label', effect: 'internal_write',
    description: 'Remove a label from one conversation.',
    arguments: { conversation_id: 'conversation ID or reference', label: 'label name' },
    required: %w[conversation_id label]
  )

  def execute(conversation_id:, label:)
    conversation = conversation!(conversation_id)
    resolved_label = label!(label)
    conversation.update!(label_list: conversation.label_list - [resolved_label.title])
    conversation_data(conversation.reload)
  end
end
