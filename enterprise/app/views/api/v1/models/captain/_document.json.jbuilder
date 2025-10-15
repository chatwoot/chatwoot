json.account_id resource.account_id
json.assistant do
  json.partial! 'api/v1/models/captain/assistant', formats: [:json], resource: resource.assistant
end
json.content resource.content
json.content_type resource.content_type
json.created_at resource.created_at.to_i
json.external_link resource.external_link
json.display_url resource.display_url
json.file_size resource.file_size
json.id resource.id
json.name resource.name
json.status resource.status
json.updated_at resource.updated_at.to_i
