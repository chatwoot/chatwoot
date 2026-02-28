class Captain::Workflows::NodeRegistry
  REGISTRY = {
    'collect_input' => Captain::Workflows::Nodes::CollectInputNode,
    'condition' => Captain::Workflows::Nodes::ConditionNode,
    'send_message' => Captain::Workflows::Nodes::SendMessageNode,
    'add_label' => Captain::Workflows::Nodes::AddLabelNode,
    'assign_agent' => Captain::Workflows::Nodes::AssignAgentNode,
    'assign_team' => Captain::Workflows::Nodes::AssignTeamNode,
    'resolve_conversation' => Captain::Workflows::Nodes::ResolveConversationNode,
    'add_private_note' => Captain::Workflows::Nodes::AddPrivateNoteNode,
    'update_priority' => Captain::Workflows::Nodes::UpdatePriorityNode,
    'shopify_search_customer' => Captain::Workflows::Nodes::Shopify::SearchCustomerNode,
    'shopify_get_customer_orders' => Captain::Workflows::Nodes::Shopify::GetCustomerOrdersNode
  }.freeze

  def self.resolve(node_type)
    REGISTRY[node_type]
  end
end
