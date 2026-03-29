json.id resource.display_id
json.title resource.title
json.description resource.description
json.message_type resource.message_type
json.status resource.status
json.account_id resource.account_id
json.template_params resource.template_params
json.inbox do
  json.partial! 'api/v1/models/inbox', formats: [:json], resource: resource.inbox
end
json.created_at resource.created_at
json.updated_at resource.updated_at
