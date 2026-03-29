json.partial! 'api/v1/models/scheduler', formats: [:json], resource: @scheduler
json.scheduled_messages @scheduled_messages do |message|
  json.id message.id
  json.external_id message.external_id
  json.customer_name message.customer_name
  json.customer_phone message.customer_phone
  json.message_type message.message_type
  json.status message.status
  json.scheduled_at message.scheduled_at
  json.sent_at message.sent_at
  json.error_message message.error_message
  json.metadata message.metadata
end
