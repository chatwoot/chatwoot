json.id message_template.id
json.account_id message_template.account_id
json.inbox_id message_template.inbox_id
json.name message_template.name
json.category message_template.category
json.language message_template.language
json.channel_type message_template.channel_type
json.status message_template.status
json.parameter_format message_template.parameter_format
json.platform_template_id message_template.platform_template_id
json.content message_template.content
json.metadata message_template.metadata
json.created_by do
  if message_template.created_by
    json.partial! 'api/v1/models/agent', formats: [:json], resource: message_template.created_by
  end
end
json.updated_by do
  if message_template.updated_by
    json.partial! 'api/v1/models/agent', formats: [:json], resource: message_template.updated_by
  end
end
json.created_at message_template.created_at.to_i
json.updated_at message_template.updated_at.to_i
json.last_synced_at message_template.last_synced_at&.to_i