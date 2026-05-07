json.id resource.id
json.content resource.content
json.account_id resource.account_id
json.contact_id resource.contact_id
json.target do
  json.type 'contact'
  json.id resource.contact_id
end

if resource.user.present?
  json.user do
    json.partial! 'api/v1/models/agent', formats: [:json], resource: resource.user
  end
  json.created_by do
    json.partial! 'api/v1/models/agent', formats: [:json], resource: resource.user
  end
end

if resource.updated_by.present?
  json.updated_by do
    json.partial! 'api/v1/models/agent', formats: [:json], resource: resource.updated_by
  end
end

json.source resource.source
json.metadata resource.metadata || {}
json.created_at resource.created_at.to_i
json.updated_at resource.updated_at.to_i
