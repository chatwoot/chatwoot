# frozen_string_literal: true

json.id scheduled_message.id
json.account_id scheduled_message.account_id
json.conversation_id scheduled_message.conversation_id
json.inbox_id scheduled_message.inbox_id
json.content scheduled_message.content
json.message_type scheduled_message.message_type
json.content_type scheduled_message.content_type
json.content_attributes scheduled_message.content_attributes
json.additional_attributes scheduled_message.additional_attributes
json.private scheduled_message.private
json.scheduled_at scheduled_message.scheduled_at.to_i
json.sent_at scheduled_message.sent_at&.to_i
json.cancelled_at scheduled_message.cancelled_at&.to_i
json.status scheduled_message.status
json.error_message scheduled_message.error_message
json.created_at scheduled_message.created_at.to_i
json.updated_at scheduled_message.updated_at.to_i

# Sender info
if scheduled_message.sender
  json.sender do
    json.partial! 'api/v1/models/agent', resource: scheduled_message.sender
  end
end

# Message info (if sent)
if scheduled_message.message
  json.message_id scheduled_message.message_id
end

# Conversation display ID
if scheduled_message.conversation
  json.conversation_display_id scheduled_message.conversation.display_id
end
