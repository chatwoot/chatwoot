# frozen_string_literal: true

# Traverses a workflow graph node by node, executing each handler.
# Manages the run lifecycle: start → execute nodes → complete/fail/handoff.
#
# Usage:
#   executor = Agent::WorkflowExecutor.new(ai_agent: agent, conversation: conv, user_message: "Hi")
#   result = executor.run
#   result.reply        # => "Hello! How can I help?"
#   result.handed_off?  # => false
class Agent::WorkflowExecutor
  MAX_NODES = 50 # Safety limit to prevent infinite loops

  ExecutionResult = Struct.new(:reply, :handed_off?, :status, :workflow_run, keyword_init: true)

  def initialize(ai_agent:, conversation:, user_message:, conversation_history: [])
    @ai_agent = ai_agent
    @conversation = conversation
    @user_message = user_message
    @conversation_history = conversation_history
    @workflow = ai_agent.workflow
  end

  def run
    validate_workflow!
    workflow_run = create_workflow_run
    context = RunContext.new(ai_agent: @ai_agent, conversation: @conversation, workflow_run: workflow_run)

    # Seed initial variables
    context.set_variable('user_message', @user_message)
    context.set_variable('conversation_id', @conversation&.id)

    # Add conversation history as context
    @conversation_history.each { |msg| context.add_message(**msg.symbolize_keys) }
    context.add_message(role: 'user', content: @user_message)

    execute_graph(context)

    complete_run(workflow_run, context)
  rescue StandardError => e
    fail_run(workflow_run, e) if workflow_run&.persisted?
    raise
  end

  private

  def validate_workflow!
    validator = WorkflowValidator.new(@workflow)
    return if validator.valid?

    raise ArgumentError, "Invalid workflow: #{validator.errors.join('; ')}"
  end

  def create_workflow_run
    Saas::WorkflowRun.create!(
      ai_agent: @ai_agent,
      conversation: @conversation,
      status: :running,
      variables: {},
      messages: [],
      execution_log: [],
      started_at: Time.current
    )
  end

  def execute_graph(context)
    nodes = @workflow['nodes'] || []
    edges = @workflow['edges'] || []

    # Find the trigger node
    trigger = nodes.find { |n| n['type'] == 'trigger' }
    current_node_id = trigger['id']
    steps = 0

    while current_node_id && steps < MAX_NODES
      steps += 1
      node_config = nodes.find { |n| n['id'] == current_node_id }
      break unless node_config

      context.workflow_run.update!(current_node_id: current_node_id)

      handler_class = NodeRegistry.handler_for(node_config['type'])
      handler = handler_class.new(node_config: node_config, context: context, edges: edges)
      result = handler.execute

      # Check for handoff or completion signals
      break if context.handed_off

      current_node_id = result[:next_node_id]
    end

    context.persist!
  end

  def complete_run(workflow_run, context)
    status = context.handed_off ? :handed_off : :completed
    workflow_run.update!(
      status: status,
      current_node_id: nil,
      completed_at: Time.current,
      variables: context.variables,
      messages: context.messages
    )

    ExecutionResult.new(
      reply: context.final_reply,
      handed_off?: context.handed_off,
      status: status.to_s,
      workflow_run: workflow_run
    )
  end

  def fail_run(workflow_run, error)
    workflow_run.update!(
      status: :failed,
      completed_at: Time.current,
      execution_log: workflow_run.execution_log + [{
        node_id: workflow_run.current_node_id,
        node_type: 'system',
        status: 'error',
        error: error.message,
        timestamp: Time.current.iso8601
      }]
    )
  end
end
