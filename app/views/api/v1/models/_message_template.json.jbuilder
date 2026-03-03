json.id resource.id
json.name resource.name
json.language resource.language
json.channel_type resource.channel_type
json.category resource.category
json.status resource.status
json.content resource.content
json.metadata resource.metadata
json.platform_template_id resource.platform_template_id
json.inbox_id resource.inbox_id
json.account_id resource.account_id
json.last_synced_at resource.last_synced_at
json.created_at resource.created_at
json.updated_at resource.updated_at
json.created_by do
  json.partial! 'api/v1/models/agent', formats: [:json], resource: resource.created_by if resource.created_by.present?
end
json.updated_by do
  json.partial! 'api/v1/models/agent', formats: [:json], resource: resource.updated_by if resource.updated_by.present?
end
