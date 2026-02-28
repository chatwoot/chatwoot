class Captain::Workflows::Nodes::TriggerNode < Captain::Workflows::Nodes::BaseNode
  def execute
    { event: node_data['event'], triggered_at: Time.current.iso8601 }
  end
end
