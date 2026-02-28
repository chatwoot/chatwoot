class Captain::Workflows::Nodes::UpdatePriorityNode < Captain::Workflows::Nodes::BaseNode
  def execute
    priority = node_data['priority']
    conversation.update!(priority: priority)
    { priority: priority }
  end
end
