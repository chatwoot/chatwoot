json.array! @attachments do |attachment|
  json.id attachment.id
  json.message_id attachment.message_id
  json.file_type attachment.file_type
  json.external_url attachment.external_url
  json.file url_for(attachment.file)
  json.created_at attachment.created_at.to_i
  json.updated_at attachment.updated_at.to_i
end
