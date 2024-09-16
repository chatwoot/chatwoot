json.id resource.id
json.content resource.content
# TODO: Temporary fix for message type cast issue, since message_type is returning as string instead of integer
json.message_type resource.reload.message_type_before_type_cast
json.content_type resource.content_type
json.content_attributes resource.content_attributes
json.created_at resource.created_at.to_i
json.conversation_id resource.conversation.display_id
json.attachments resource.attachments.map(&:push_event_data) if resource.attachments.present?
json.sender resource.sender.push_event_data if resource.sender
