json.id resource.id
json.content resource.content
json.message_type resource.message_type_before_type_cast
json.content_type resource.content_type
json.content_attributes resource.content_attributes
json.created_at resource.created_at.to_i
json.conversation_id resource.conversation.display_id
json.attachments resource.attachments.map(&:push_event_data) if resource.attachments.present?
json.sender { json.partial! 'api/v1/models/widget_sender', sender: resource.sender } if resource.sender
