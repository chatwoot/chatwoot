json.traces @traces do |trace|
  json.id trace.id
  json.created_at trace.created_at
  json.outcome trace.outcome
  json.source trace.source
  json.input_message trace.input_message
  json.error_reason trace.error_reason
  json.trace trace.trace
  json.response trace.response

  json.assistant_name trace.assistant.name
  json.conversation_display_id trace.conversation&.display_id
  json.contact_name trace.conversation&.contact&.name
end
json.meta do
  json.count @traces_count
end