json.id resource.id
json.rating resource.rating
json.feedback_message resource.feedback_message
json.csat_review_notes resource.csat_review_notes
json.review_notes_updated_at resource.review_notes_updated_at&.to_i
if resource.review_notes_updated_by
  json.review_notes_updated_by do
    json.id resource.review_notes_updated_by.id
    json.name resource.review_notes_updated_by.name
  end
end
json.account_id resource.account_id
json.message_id resource.message_id
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
