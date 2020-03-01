json.meta do
end

json.payload do
  json.success @status
  json.current_status @conversation.status
  json.conversation_id @conversation.display_id
end
