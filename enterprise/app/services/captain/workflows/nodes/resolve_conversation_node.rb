class Captain::Workflows::Nodes::ResolveConversationNode < Captain::Workflows::Nodes::BaseNode
  def execute
    conversation.resolve!
    { resolved: true }
  end
end
