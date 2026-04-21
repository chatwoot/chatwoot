json.id @inbox_limit.id
json.inbox_id @inbox_limit.inbox_id
json.inbox_name @inbox_limit.inbox.name
json.agent_capacity_policy_id @agent_capacity_policy.id
json.conversation_limit @inbox_limit.conversation_limit
json.created_at @inbox_limit.created_at.to_i
json.updated_at @inbox_limit.updated_at.to_i
