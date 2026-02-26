json.id resource.id
json.content resource.content
json.order_id resource.order_id
if resource.user.present?
  json.user do
    json.partial! 'api/v1/models/agent', formats: [:json], resource: resource.user
  end
end
json.created_at resource.created_at.to_i
json.updated_at resource.updated_at.to_i
