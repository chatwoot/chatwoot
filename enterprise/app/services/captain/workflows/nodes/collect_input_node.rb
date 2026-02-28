class Captain::Workflows::Nodes::CollectInputNode < Captain::Workflows::Nodes::BaseNode
  def execute
    input_key = node_data['input_key'] || 'user_input'

    if context[input_key].present?
      { collected: context[input_key] }
    else
      { status: 'input_required', prompt: node_data['prompt'] || 'Please provide input', input_key: input_key }
    end
  end
end
