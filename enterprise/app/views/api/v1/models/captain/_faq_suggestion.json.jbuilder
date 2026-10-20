json.id resource.id
json.account_id resource.account_id
json.question resource.question
json.answer resource.answer
json.language resource.language
json.source_count resource.source_count
json.status resource.status
json.created_at resource.created_at.to_i
json.updated_at resource.updated_at.to_i
json.assistant do
  json.partial! 'api/v1/models/captain/assistant', formats: [:json], resource: resource.assistant
end
