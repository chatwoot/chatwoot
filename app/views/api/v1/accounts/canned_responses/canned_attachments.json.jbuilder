json.payload @canned_attachments do |canned_attachment|
  json.canned_response_id canned_attachment.push_event_data[:canned_response_id]
  json.thumb_url canned_attachment.push_event_data[:thumb_url]
  json.data_url canned_attachment.push_event_data[:data_url]
  json.file_size canned_attachment.push_event_data[:file_size]
  json.file_type canned_attachment.push_event_data[:file_type]
  json.extension canned_attachment.push_event_data[:extension]
  json.width canned_attachment.push_event_data[:width]
  json.height canned_attachment.push_event_data[:height]
  json.created_at canned_attachment.canned_response.created_at.to_i
  json.blob canned_attachment.file_blob
end
