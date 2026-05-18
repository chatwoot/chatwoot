json.meta do
  json.total_count @attachments_count
end

json.payload @attachments do |attachment|
  json.partial! 'api/v1/models/attachment', formats: [:json], attachment: attachment
  json.conversation_id attachment.message.conversation.display_id
end
