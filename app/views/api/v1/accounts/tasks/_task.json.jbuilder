json.id task.id
json.title task.title.capitalize
json.description task.description.capitalize
json.status task.status
json.action_type task.action_type
json.assignee_id task.assignee_id
json.agent_bot_id task.agent_bot_id
json.execution_config task.execution_config
json.entity_type task.entity_type
json.entity_id task.entity_id
json.creator_id task.creator_id
json.created_at task.created_at
json.updated_at task.updated_at

if task.creator.present?
  json.creator do
    json.id task.creator.id
    json.name task.creator.name
    json.avatar_url task.creator.avatar_url
  end
else
  json.creator nil
end

if task.assignee.present?
  json.assignee do
    json.id task.assignee.id
    json.name task.assignee.name
    json.avatar_url task.assignee.avatar_url
  end
else
  json.assignee nil
end

if task.agent_bot.present?
  json.agent_bot do
    json.id task.agent_bot.id
    json.name task.agent_bot.name
    json.outgoing_url task.agent_bot.outgoing_url
  end
else
  json.agent_bot nil
end
