class Captain::Workflows::Nodes::AddLabelNode < Captain::Workflows::Nodes::BaseNode
  def execute
    label = node_data['label']
    conversation.label_list.add(label)
    conversation.save!
    { label: label }
  end
end
