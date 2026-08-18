json.payload @inboxes do |inbox|
  json.inbox_id inbox.id
  json.name inbox.name
  json.phone_number inbox.channel.phone_number
  json.agent_bot_id inbox.agent_bot_inbox&.agent_bot_id
end
