json.id conversation.display_id
json.inbox_id conversation.inbox_id
json.status conversation.status
json.widget_section conversation.additional_attributes['widget_section'] || 'human'
json.ai_state widget_conversation_ai_state(conversation)
json.unread_count local_assigns.fetch(:unread_count, 0)
json.contact_last_seen_at conversation.contact_last_seen_at.to_i
json.created_at conversation.created_at.to_i
json.last_activity_at conversation.last_activity_at.to_i
json.custom_attributes conversation.custom_attributes

if conversation.assignee.present?
  json.assignee do
    json.name conversation.assignee.available_name
    json.avatar_url conversation.assignee.avatar_url
    json.availability_status conversation.assignee.availability_status
  end
else
  json.assignee nil
end

last_message = conversation.messages.where(private: false).where.not(message_type: :activity).order(created_at: :desc).first
if last_message.present?
  json.last_message do
    json.partial! 'api/v1/models/widget_message', resource: last_message
  end
else
  json.last_message nil
end
