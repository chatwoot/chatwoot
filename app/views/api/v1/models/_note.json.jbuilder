json.id resource.id
json.content resource.content
json.account_id json.account_id
json.contact_id json.contact_id
json.user do
  json.partial! 'api/v1/models/agent.json.jbuilder', resource: resource.user
end
json.created_at resource.created_at
json.updated_at resource.updated_at
