json.meta do
end

json.payload do
  json.success @status
  json.conversation_id @conversation.display_id
  json.current_status @conversation.status
  json.snoozed_until @conversation.snoozed_until
end
