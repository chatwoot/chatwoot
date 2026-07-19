json.id resource.id
json.account_id resource.account_id
json.internal_conversation_id resource.internal_conversation_id
json.user_id resource.user_id
json.content resource.content
json.created_at resource.created_at.to_i

if resource.user.present?
  json.user do
    json.partial! 'api/v1/models/agent', formats: [:json], resource: resource.user
  end
end
