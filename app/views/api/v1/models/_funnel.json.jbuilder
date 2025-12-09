json.id resource.id
json.name resource.name
json.account_id resource.account_id
json.team_id resource.team_id
json.columns resource.columns
json.position resource.position
json.is_default resource.is_default
json.created_at resource.created_at.to_i
json.updated_at resource.updated_at.to_i

if resource.team.present?
  json.team do
    json.id resource.team.id
    json.name resource.team.name
  end
end

