class Captain::Workflows::ExecutionService
  attr_reader :workflow, :context, :execution

  def initialize(workflow, context)
    @workflow = workflow
    @context = context.with_indifferent_access
  end

  def perform
    @execution = create_execution
    execution.update!(status: :running, started_at: Time.current)

    traverse_graph
    execution.update!(status: :completed, completed_at: Time.current)
  rescue StandardError => e
    execution&.update!(status: :failed, completed_at: Time.current, error_message: e.message)
    Rails.logger.error("[CaptainWorkflow] Workflow #{workflow.id} failed: #{e.message}")
  end

  private

  def create_execution
    Captain::WorkflowExecution.create!(
      workflow: workflow,
      account: workflow.account,
      conversation_id: context[:conversation]&.id,
      contact_id: context[:contact]&.id,
      status: :pending,
      execution_log: []
    )
  end

  def traverse_graph
    nodes = workflow.nodes
    edges = workflow.edges
    return if nodes.blank?

    trigger_node = nodes.find { |n| n['type']&.start_with?('trigger_') }
    return unless trigger_node

    visited = Set.new
    execute_node(trigger_node, nodes, edges, visited)
  end

  def execute_node(node, nodes, edges, visited)
    node_id = node['id']
    return if visited.include?(node_id)

    visited.add(node_id)

    executor_class = Captain::Workflows::NodeRegistry.resolve(node['type'])
    unless executor_class
      log_step(node_id, node['type'], 'skipped', { reason: 'unknown node type' })
      return
    end

    executor = executor_class.new(node, context)
    result = executor.execute
    log_step(node_id, node['type'], 'completed', result)

    next_edges = find_next_edges(node_id, edges, result)
    next_edges.each do |edge|
      target_node = nodes.find { |n| n['id'] == edge['target'] }
      execute_node(target_node, nodes, edges, visited) if target_node
    end
  end

  def find_next_edges(node_id, edges, result)
    outgoing = edges.select { |e| e['source'] == node_id }

    if result.is_a?(Hash) && result[:next_handle]
      outgoing.select { |e| e['sourceHandle'] == result[:next_handle] }
    else
      outgoing
    end
  end

  def log_step(node_id, node_type, status, result)
    execution.execution_log << {
      node_id: node_id,
      node_type: node_type,
      status: status,
      result: result,
      timestamp: Time.current.iso8601
    }
    execution.save!
  end
end
