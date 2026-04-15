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
json.sync_status resource.sync_status
json.last_synced_at resource.last_synced_at&.to_i
json.last_sync_attempted_at resource.last_sync_attempted_at&.to_i
json.last_sync_error_code resource.last_sync_error_code
json.updated_at resource.updated_at.to_i
