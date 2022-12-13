json.id message.id
json.content message.content
json.inbox_id message.inbox_id
json.echo_id message.echo_id if message.echo_id
# For deleted conversation, messages are not yet deleted [because of destroy_async] for this we added try block
json.conversation_id message.conversation.try(:display_id)
json.message_type message.message_type_before_type_cast
json.content_type message.content_type
json.status message.status
json.content_attributes message.content_attributes
json.created_at message.created_at.to_i
json.private message.private
json.source_id message.source_id
json.sender message.sender.push_event_data if message.sender
json.attachments message.attachments.map(&:push_event_data) if message.attachments.present?
