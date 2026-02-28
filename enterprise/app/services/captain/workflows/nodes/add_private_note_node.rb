class Captain::Workflows::Nodes::AddPrivateNoteNode < Captain::Workflows::Nodes::BaseNode
  def execute
    content = interpolate(node_data['message'])
    note = conversation.messages.create!(
      account: account,
      message_type: :activity,
      content: content,
      private: true
    )
    { note_id: note.id }
  end
end
