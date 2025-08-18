json.id @message.id
json.content @message.content
json.inbox_id @message.inbox_id
json.conversation_id @message.conversation.display_id
json.message_type @message.message_type_before_type_cast
json.created_at @message.created_at.to_i
json.private @message.private
json.source_id @message.source_id
json.content_attributes @message.content_attributes
json.attachments @message.attachments.map(&:push_event_data) if @message.attachments.present?
json.sender @message.sender.push_event_data if @message.sender
