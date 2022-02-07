json.id resource.id
json.content resource.content
json.account_id json.account_id
json.contact_id json.contact_id
if resource.user.present?
  json.user do
    json.partial! 'api/v1/models/agent.json.jbuilder', resource: resource.user
  end
end
json.created_at resource.created_at.to_i
json.updated_at resource.updated_at.to_i
