attachment_data = attachment.push_event_data

json.id attachment_data[:id]
json.message_id attachment_data[:message_id]
json.thumb_url attachment_data[:thumb_url]
json.data_url attachment_data[:data_url]
json.file_size attachment_data[:file_size]
json.file_type attachment_data[:file_type]
json.extension attachment_data[:extension]
json.width attachment_data[:width]
json.height attachment_data[:height]
json.created_at attachment.message.created_at.to_i
json.sender attachment.message.sender.push_event_data if attachment.message.sender
