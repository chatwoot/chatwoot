class Captain::Tools::ExecuteWorkflowService < Captain::Tools::BaseTool
  def self.name
    'execute_workflow'
  end

  description 'Execute or continue a workflow. Use workflow_id to start a new workflow, execution_id to continue a paused one.'

  param :workflow_id, desc: 'ID of workflow to start (for new executions)', required: false
  param :execution_id, desc: 'ID of paused execution to continue', required: false
  param :user_input, desc: 'User response for the current step', required: false

  def execute(workflow_id: nil, execution_id: nil, user_input: nil)
    if execution_id.present?
      continue_execution(execution_id, user_input)
    elsif workflow_id.present?
      start_execution(workflow_id)
    else
      'Provide either workflow_id to start or execution_id to continue a workflow.'
    end
  end

  private

  def start_execution(workflow_id)
    workflow = assistant.workflows.enabled.find_by(id: workflow_id)
    return "Workflow #{workflow_id} not found or not enabled." unless workflow

    context = build_context
    result = Captain::Workflows::ExecutionService.new(workflow, context).perform
    format_result(result)
  end

  def continue_execution(execution_id, user_input)
    execution = Captain::WorkflowExecution.find_by(id: execution_id, status: :waiting_for_input)
    return "Execution #{execution_id} not found or not waiting for input." unless execution

    result = Captain::Workflows::ExecutionService.resume(execution, user_input)
    format_result(result)
  end

  def build_context
    context = { account: assistant.account }
    if @conversation
      context[:conversation] = @conversation
      context[:contact] = @conversation.contact
    end
    context
  end

  def format_result(result)
    return result.to_json unless result.is_a?(Hash)

    case result[:status]
    when 'input_required'
      "Workflow paused. Need user input: #{result[:prompt]} (input_key: #{result[:input_key]}). " \
      "To continue, call execute_workflow(execution_id: #{result[:execution_id]}, user_input: \"<user's response>\")."
    when 'completed'
      "Workflow completed successfully. Actions taken: #{result[:actions].to_json}"
    when 'failed'
      "Workflow failed: #{result[:error]}"
    else
      result.to_json
    end
  end
end
