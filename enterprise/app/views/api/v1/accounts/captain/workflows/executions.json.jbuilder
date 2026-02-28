json.payload do
  json.array! @executions do |execution|
    json.id execution.id
    json.workflow_id execution.workflow_id
    json.conversation_id execution.conversation_id
    json.contact_id execution.contact_id
    json.status execution.status
    json.started_at execution.started_at
    json.completed_at execution.completed_at
    json.error_message execution.error_message
    json.execution_log execution.execution_log
    json.created_at execution.created_at
  end
end
