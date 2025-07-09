class Captain::Tools::AddPrivateNoteTool < Captain::Tools::BaseAgentTool
  description 'Add a private note to a conversation'
  param :conversation_id, type: 'string', desc: 'The display ID of the conversation'
  param :note, type: 'string', desc: 'The private note content'

  def perform(_tool_context, conversation_id:, note:)
    log_tool_usage('add_private_note', { conversation_id: conversation_id, note_length: note.length })

    return 'Missing required parameters' if conversation_id.blank? || note.blank?

    conversation = account_scoped(::Conversation).find_by(display_id: conversation_id)
    return 'Conversation not found' if conversation.nil?

    # Create private note message
    conversation.messages.create!(
      account: @assistant.account,
      inbox: conversation.inbox,
      sender: @user,
      content: note,
      message_type: 'activity',
      private: true
    )

    "Private note added successfully to conversation #{conversation_id}"
  end

  def active?
    user_has_permission('conversation_manage') ||
      user_has_permission('conversation_unassigned_manage') ||
      user_has_permission('conversation_participating_manage')
  end
end
