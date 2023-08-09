if @conversation
  json.id @conversation.display_id
  json.inbox_id @conversation.inbox_id
  json.contact_last_seen_at @conversation.contact_last_seen_at.to_i
  json.status @conversation.status
  json.messages @conversation.messages do |message|
    json.id message.id
    json.content message.content
    json.message_type message.message_type_before_type_cast
    json.content_type message.content_type
    json.content_attributes message.content_attributes
    json.created_at message.created_at.to_i
    json.conversation_id message.conversation.display_id
    json.attachments message.attachments.map(&:push_event_data) if message.attachments.present?
    json.sender message.sender.push_event_data if message.sender
  end
end
