json.array! resource do |chatbot|
  json.id chatbot.id
  json.name chatbot.chatbot_name
  json.last_trained_at chatbot.last_trained_at
  json.inbox_id chatbot.inbox_id
  json.status chatbot.bot_status
end