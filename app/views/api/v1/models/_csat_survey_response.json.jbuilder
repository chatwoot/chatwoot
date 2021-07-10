json.id resource.id
json.rating resource.rating
json.feedback_message resource.feedback_message
json.account_id resource.account_id
json.message_id resource.message_id
json.contact do
  json.partial! 'api/v1/models/contact.json.jbuilder', resource: resource.contact
end if resource.contact
json.conversation_id resource.conversation.display_id
json.assigned_agent do
  json.partial! 'api/v1/models/agent.json.jbuilder', resource: resource.assigned_agent
end if resource.assigned_agent
json.created_at resource.created_at
