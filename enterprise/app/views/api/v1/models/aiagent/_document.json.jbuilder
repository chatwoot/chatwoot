json.account_id resource.account_id
json.topic do
  json.partial! 'api/v1/models/aiagent/topic', formats: [:json], resource: resource.topic
end
json.content resource.content
json.created_at resource.created_at.to_i
json.external_link resource.external_link
json.id resource.id
json.name resource.name
json.status resource.status
json.updated_at resource.updated_at.to_i
