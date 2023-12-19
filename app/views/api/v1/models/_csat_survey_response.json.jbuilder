json.id resource.id
json.rating resource.rating
json.feedback_message resource.feedback_message
json.account_id resource.account_id
json.message_id resource.message_id
json.csat_question_id resource.message.csat_template_question&.id

if resource.message.csat_template_question
  json.csat_question resource.message.csat_template_question.content
else
  json.csat_question resource.message.content
end

if resource.contact
  json.contact do
    json.partial! 'api/v1/models/contact', formats: [:json], resource: resource.contact
  end
end
json.conversation_id resource.conversation.display_id
if resource.assigned_agent
  json.assigned_agent do
    json.partial! 'api/v1/models/agent', formats: [:json], resource: resource.assigned_agent
  end
end
json.created_at resource.created_at.to_i
