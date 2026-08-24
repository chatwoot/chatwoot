# frozen_string_literal: true

# [whisker] Executes a conversation flow by traversing nodes and edges
class FlowExecutionService
  pattr_initialize [:flow!, :conversation!, { message: nil }]

  def perform
    return unless flow.enabled?

    nodes = flow.flow_data['nodes'] || []
    edges = flow.flow_data['edges'] || []
    return if nodes.empty?

    start_node = nodes.find { |n| n['type'] == 'trigger' } || nodes.first
    execute_node(start_node, nodes, edges)
  ensure
    flow.increment!(:execution_count)
  end

  private

  def execute_node(node, nodes, edges)
    return unless node

    result = process_node(node)

    # Find next node based on result
    outgoing = edges.select { |e| e['source'] == node['id'] }
    next_edge = if result.nil?
                  outgoing.first
                else
                  outgoing.find { |e| e['label'] == result.to_s } || outgoing.first
                end

    return unless next_edge

    next_node = nodes.find { |n| n['id'] == next_edge['target'] }
    execute_node(next_node, nodes, edges)
  end

  def process_node(node)
    case node['type']
    when 'trigger'
      process_trigger(node)
    when 'condition'
      process_condition(node)
    when 'action'
      process_action(node)
    when 'ai_reply'
      process_ai_reply(node)
    when 'send_message'
      process_send_message(node)
    else
      Rails.logger.warn("[FlowBuilder] Unknown node type: #{node['type']}")
    end
  end

  def process_trigger(node)
    # Trigger nodes just start the flow, always pass
    true
  end

  def process_condition(node)
    data = node['data'] || {}
    field = data['field']
    operator = data['operator']
    expected = data['value']
    actual = resolve_field(field)

    case operator
    when 'equals' then actual.to_s == expected.to_s
    when 'not_equals' then actual.to_s != expected.to_s
    when 'contains' then actual.to_s.include?(expected.to_s)
    when 'greater_than' then actual.to_f > expected.to_f
    when 'less_than' then actual.to_f < expected.to_f
    else false
    end
  end

  def process_action(node)
    data = node['data'] || {}
    case data['action']
    when 'assign_agent'
      conversation.update!(assignee_id: data['agent_id'])
    when 'set_status'
      conversation.update!(status: data['status'])
    when 'add_label'
      conversation.add_label(data['label'])
    when 'remove_label'
      conversation.remove_label(data['label'])
    when 'send_notification'
      # Trigger notification
    end
    true
  end

  def process_ai_reply(node)
    data = node['data'] || {}
    prompt = data['prompt'] || ''

    task = AiAutoReplyService::AiReplyTask.new(
      account: conversation.account,
      conversation: conversation
    )
    result = task.perform
    return if result[:error]

    Messenger::MessageBuilder.new(
      conversation: conversation,
      message_type: :outgoing,
      content: result[:message],
      private: false
    ).perform
    true
  end

  def process_send_message(node)
    data = node['data'] || {}
    content = data['content'] || ''
    return if content.blank?

    Messenger::MessageBuilder.new(
      conversation: conversation,
      message_type: :outgoing,
      content: content,
      private: false
    ).perform
    true
  end

  def resolve_field(field)
    case field
    when 'inbox_id' then conversation.inbox_id
    when 'status' then conversation.status
    when 'assignee_id' then conversation.assignee_id
    when 'contact_name' then conversation.contact&.name
    when 'contact_email' then conversation.contact&.email
    when 'message_content' then message&.content
    else conversation.send(field) if conversation.respond_to?(field)
    end
  end
end
