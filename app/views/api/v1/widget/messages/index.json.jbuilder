json.array! @messages do |message|
  json.id message.id
  json.content message.content
  json.message_type message.message_type_before_type_cast
  json.content_type message.content_type
  json.content_attributes message.content_attributes
  json.created_at message.created_at.to_i
  json.conversation_id message. conversation_id
  json.attachment message.attachment.push_event_data if message.attachment
  json.sender message.user.push_event_data if message.user
end
