if @conversation
  json.id @conversation.display_id
  json.inbox_id @conversation.inbox_id
  json.status @conversation.status
end
