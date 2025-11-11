json.payload do
  json.assignee @conversation.assignee
  json.assignee_agent_bot @conversation.assignee_agent_bot
  json.assignee_type @conversation.assignee_type
  json.conversation_id @conversation.display_id
end
