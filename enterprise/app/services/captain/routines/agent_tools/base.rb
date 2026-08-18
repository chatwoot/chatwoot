require 'agents'

class Captain::Routines::AgentTools::Base < Agents::Tool
  private

  def perform_operation(tool_context, name, arguments = {})
    operation = Captain::Routines::Operations::Registry.fetch(name)
    raise Captain::Routines::OperationError, "Operation '#{name}' is not available" unless operation

    result = operation.execute(context: runtime(tool_context), arguments: arguments)
    record_tool_result(tool_context, operation, 'completed', result: result)
    { status: 'completed', operation: name, result: result }.to_json
  rescue StandardError => e
    record_tool_result(tool_context, operation, 'failed', error: e.message) if operation
    { status: 'failed', operation: name, error: e.message }.to_json
  end

  def current_conversation_id(tool_context)
    tool_context.state.fetch(:conversation_id)
  end

  def current_conversation(tool_context)
    runtime(tool_context).account.conversations.find(current_conversation_id(tool_context))
  end

  def runtime(tool_context)
    tool_context.context.fetch(:routine_runtime)
  end

  def record_tool_result(tool_context, operation, status, result: nil, error: nil)
    event = {
      'path' => tool_context.state[:path],
      'type' => 'agent_tool',
      'status' => status,
      'operation' => operation.operation_name,
      'effect' => operation.effect,
      'record_id' => current_conversation_id(tool_context),
      'at' => Time.current.iso8601
    }.compact
    runtime(tool_context).record(event)
    return if operation.kind == 'query'

    receipt = event.slice('operation', 'effect', 'status', 'record_id', 'at')
    receipt['result'] = receipt_result(result) if result
    receipt['error'] = error if error
    (tool_context.state[:receipts] ||= []) << receipt
  end

  def receipt_result(result)
    return result unless result.is_a?(Hash)

    result.slice(
      'id', 'display_id', 'status', 'priority', 'snoozed_until', 'labels', 'assignee', 'team',
      'message_type', 'private', 'payment_id', 'amount_cents', 'currency', 'reason', 'created_at'
    )
  end
end
