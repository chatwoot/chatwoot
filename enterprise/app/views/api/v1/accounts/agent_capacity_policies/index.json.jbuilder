json.array! @agent_capacity_policies do |policy|
  json.id policy.id
  json.name policy.name
  json.description policy.description
  json.exclusion_rules policy.exclusion_rules
  json.created_at policy.created_at
  json.updated_at policy.updated_at
  json.account_id policy.account_id
  json.inbox_capacity_limits policy.inbox_capacity_limits do |limit|
    json.id limit.id
    json.inbox_id limit.inbox_id
    json.conversation_limit limit.conversation_limit
  end
end
