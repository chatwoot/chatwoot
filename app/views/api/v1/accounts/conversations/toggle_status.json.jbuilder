json.meta do
end

json.payload do
  json.success @status
  json.conversation_id @conversation.display_id
  json.current_status @conversation.status
  json.snoozed_until @conversation.snoozed_until
  json.classification_id @conversation.classification_id
  json.closing_note @conversation.closing_note
  if @conversation.classification.present?
    json.classification do
      json.id @conversation.classification.id
      json.name @conversation.classification.name
    end
  else
    json.classification nil
  end
end
