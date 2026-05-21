json.id agent_capacity_policy.id
json.name agent_capacity_policy.name
json.description agent_capacity_policy.description
json.exclusion_rules agent_capacity_policy.exclusion_rules
json.created_at agent_capacity_policy.created_at.to_i
json.updated_at agent_capacity_policy.updated_at.to_i
json.account_id agent_capacity_policy.account_id
json.assigned_agent_count agent_capacity_policy.account_users.count

json.inbox_capacity_limits agent_capacity_policy.inbox_capacity_limits do |limit|
  json.id limit.id
  json.inbox_id limit.inbox_id
  json.conversation_limit limit.conversation_limit
end
