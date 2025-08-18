json.array! @agent_capacity_policies do |policy|
  json.id policy.id
  json.name policy.name
  json.description policy.description
  json.exclusion_rules policy.exclusion_rules
  json.created_at policy.created_at.to_i
  json.updated_at policy.updated_at.to_i
  json.account_id policy.account_id
end
