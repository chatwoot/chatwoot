if @conversation
  json.id @conversation.display_id
  json.inbox_id @conversation.inbox_id
  json.user_last_seen_at @conversation.user_last_seen_at.to_i
  json.status @conversation.status
end
