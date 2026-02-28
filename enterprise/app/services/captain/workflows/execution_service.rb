class Captain::Workflows::ExecutionService
  attr_reader :workflow, :context, :execution

  def initialize(workflow, context)
    @workflow = workflow
    @context = context.with_indifferent_access
    @paused = false
  end

  def perform
    @execution = create_execution
    execution.update!(status: :running, started_at: Time.current)
    traverse_graph
    finalize_execution
  rescue StandardError => e
    handle_failure(e)
  end

  def self.resume(execution, user_input)
    context = build_resume_context(execution, user_input)
    service = new(execution.workflow, context)
    service.resume_from(execution)
  end

  def resume_from(existing_execution)
    @execution = existing_execution
    @paused = false
    execution.update!(status: :running)

    resume_from_paused_node
    finalize_execution
  rescue StandardError => e
    handle_failure(e, 'resume')
  end

  def self.build_resume_context(execution, user_input)
    context = execution.context_store.with_indifferent_access
    context[:account] = execution.workflow.account
    context[:conversation] = execution.conversation if execution.conversation
    context[:contact] = execution.contact if execution.contact

    paused_node = execution.workflow.nodes.find { |n| n['id'] == execution.current_node_id }
    input_key = paused_node&.dig('data', 'input_key') || 'user_input'
    context[input_key] = user_input
    context
  end

  private

  def resume_from_paused_node
    nodes = workflow.nodes
    edges = workflow.edges
    paused_node = nodes.find { |n| n['id'] == execution.current_node_id }
    return unless paused_node

    execute_node(paused_node, nodes, edges, Set.new)
  end

  def finalize_execution
    if @paused
      save_paused_state
      { status: 'input_required', prompt: @pause_result[:prompt], input_key: @pause_result[:input_key], execution_id: execution.id }
    else
      execution.update!(status: :completed, completed_at: Time.current)
      { status: 'completed', actions: execution.execution_log }
    end
  end

  def save_paused_state
    execution.update!(status: :waiting_for_input, current_node_id: @pause_node_id, context_store: serializable_context)
  end

  def handle_failure(error, label = nil)
    execution&.update!(status: :failed, completed_at: Time.current, error_message: error.message)
    tag = label ? " #{label}" : ''
    Rails.logger.error("[CaptainWorkflow] Workflow #{workflow.id}#{tag} failed: #{error.message}")
    { status: 'failed', error: error.message }
  end

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

    entry_nodes = find_entry_nodes(nodes, edges)
    return if entry_nodes.empty?

    visited = Set.new
    entry_nodes.each do |entry_node|
      break if @paused

      execute_node(entry_node, nodes, edges, visited)
    end
  end

  def find_entry_nodes(nodes, edges)
    target_ids = edges.to_set { |e| e['target'] }
    nodes.reject { |n| target_ids.include?(n['id']) }
  end

  def execute_node(node, nodes, edges, visited)
    return if @paused

    node_id = node['id']
    return if visited.include?(node_id)

    visited.add(node_id)

    result = run_node_executor(node)
    return unless result

    return pause_at(node_id, result) if input_required?(result)

    follow_edges(node_id, nodes, edges, result, visited)
  end

  def run_node_executor(node)
    executor_class = Captain::Workflows::NodeRegistry.resolve(node['type'])
    unless executor_class
      log_step(node['id'], node['type'], 'skipped', { reason: 'unknown node type' })
      return nil
    end

    result = executor_class.new(node, context).execute
    log_step(node['id'], node['type'], 'completed', result)
    result
  end

  def input_required?(result)
    result.is_a?(Hash) && result[:status] == 'input_required'
  end

  def pause_at(node_id, result)
    @paused = true
    @pause_node_id = node_id
    @pause_result = result
  end

  def follow_edges(node_id, nodes, edges, result, visited)
    next_edges = find_next_edges(node_id, edges, result)
    next_edges.each do |edge|
      break if @paused

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

  def serializable_context
    context.each_with_object({}) do |(key, value), hash|
      next if value.is_a?(ActiveRecord::Base)

      hash[key] = value
    end
  end
end
