class Captain::Workflows::Nodes::AssignAgentNode < Captain::Workflows::Nodes::BaseNode
  def execute
    agent_id = node_data['agent_id']
    conversation.update!(assignee_id: agent_id)
    { agent_id: agent_id }
  end
end
