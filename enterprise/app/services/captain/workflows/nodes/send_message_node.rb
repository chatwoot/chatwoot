class Captain::Workflows::Nodes::SendMessageNode < Captain::Workflows::Nodes::BaseNode
  def execute
    content = interpolate(node_data['message'])
    message = conversation.messages.create!(
      account: account,
      message_type: :outgoing,
      content: content
    )
    { message_id: message.id }
  end
end
