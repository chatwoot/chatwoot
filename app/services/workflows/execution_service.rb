class Workflows::ExecutionService
  pattr_initialize [:workflow!, :event_name!, :event_data!]

  MAX_NODES = 50

  def perform
    return unless workflow.active?

    @visited_nodes = Set.new
    trigger_node = workflow.nodes.find { |n| n['type'] == 'trigger' }
    return unless trigger_node

    execute_node(trigger_node)
  end

  private

  def execute_node(node)
    return if node.nil?
    return if @visited_nodes.include?(node['id'])
    return if @visited_nodes.size >= MAX_NODES

    @visited_nodes.add(node['id'])

    case node['type']
    when 'trigger'
      follow_edges(node['id'])
    when 'condition'
      result = evaluate_condition(node['data'])
      follow_edges(node['id'], result.to_s)
    when 'action'
      execute_action(node['data'])
      follow_edges(node['id'])
    when 'ai_prompt'
      execute_ai_prompt(node['data'])
      follow_edges(node['id'])
    end
  end

  def follow_edges(node_id, source_handle = nil)
    matched_edges = workflow.edges.select { |e| e['source'] == node_id }
    matched_edges = matched_edges.select { |e| e['sourceHandle'] == source_handle } if source_handle

    matched_edges.each do |edge|
      next_node = workflow.nodes.find { |n| n['id'] == edge['target'] }
      execute_node(next_node)
    end
  end

  def evaluate_condition(data)
    target = fetch_target_object
    return false unless target

    attr_value = target.try(data['attribute'].to_sym) || target.try(:custom_attributes)&.dig(data['attribute'])

    case data['operator']
    when 'contains'
      attr_value.to_s.downcase.include?(data['value'].to_s.downcase)
    when 'equals'
      attr_value.to_s.downcase == data['value'].to_s.downcase
    else
      false
    end
  end

  def execute_action(data)
    target = fetch_target_object
    return unless target

    case data['action_name']
    when 'send_message'
      send_message(data['action_params'])
    when 'add_label'
      add_label(data['action_params'])
    end
  end

  def execute_ai_prompt(_data)
    Rails.logger.info("[Workflows] AI Prompt node encountered — not yet implemented for MVP")
  end

  def fetch_target_object
    case event_name
    when 'message_created'
      event_data[:message]
    when 'conversation_created', 'conversation_updated', 'conversation_opened', 'conversation_resolved'
      event_data[:conversation]
    end
  end

  def resolve_conversation(target)
    target.is_a?(Conversation) ? target : target.try(:conversation)
  end

  def send_message(params)
    conversation = resolve_conversation(fetch_target_object)
    return unless conversation

    Message.create!(
      conversation: conversation,
      account: conversation.account,
      sender: workflow,
      content: params['content'],
      message_type: :outgoing
    )
  end

  def add_label(params)
    conversation = resolve_conversation(fetch_target_object)
    return unless conversation

    conversation.label_list.add(params['label'])
    conversation.save!
  end
end
