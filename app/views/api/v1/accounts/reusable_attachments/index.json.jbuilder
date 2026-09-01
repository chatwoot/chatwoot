json.array! @reusable_attachments do |attachment|
  json.id attachment.id
  json.name attachment.name
  json.file_type attachment.file_type
  json.extension attachment.extension
  json.description attachment.description
  json.file_url attachment.file_url
  json.download_url attachment.download_url
  json.thumb_url attachment.thumb_url
  json.file_size attachment.file_size
  json.created_at attachment.created_at
  json.updated_at attachment.updated_at
end
