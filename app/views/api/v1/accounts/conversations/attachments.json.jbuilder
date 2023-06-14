json.payload @attachments do |attachment|
  json.attachment attachment.push_event_data
  json.sender attachment.message.sender.push_event_data if attachment.message.sender
  json.created_at attachment.message.created_at.to_i
end
