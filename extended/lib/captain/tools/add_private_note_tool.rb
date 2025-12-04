class Captain::Tools::AddPrivateNoteTool < Captain::Tools::BasePublicTool
  description 'Add a private note to a conversation'
  param :note, type: 'string', desc: 'The private note content'

  def perform(tool_context, note:)
    conversation = find_conversation(tool_context.state)
    return 'Conversation not found' unless conversation

    return 'Note content is required' if note.blank?

    log_tool_usage('add_private_note', { conversation_id: conversation.id, note_length: note.length })
    create_private_note(conversation, note)

    'Private note added successfully'
  end

  private

  def create_private_note(conversation, note)
    conversation.messages.create!(
      account: @assistant.account,
      inbox: conversation.inbox,
      sender: @assistant,
      message_type: :outgoing,
      content: note,
      private: true
    )
  end

  def permissions
    %w[conversation_manage conversation_unassigned_manage conversation_participating_manage]
  end
end
