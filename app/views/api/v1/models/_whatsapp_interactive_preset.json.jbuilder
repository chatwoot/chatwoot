json.extract! whatsapp_interactive_preset, :id, :name, :interactive_type, :schema_version, :definition, :created_at, :updated_at

json.attachments whatsapp_interactive_preset.media do |medium|
  json.position medium.position
  json.signed_id medium.file.blob.signed_id
  json.file_type medium.media_type
  json.content_type medium.file.blob.content_type
  json.filename medium.file.blob.filename.to_s
  json.file_size medium.file.blob.byte_size
  json.data_url url_for(medium.file)
end

json.creator do
  if whatsapp_interactive_preset.creator_active?
    json.id whatsapp_interactive_preset.created_by_id
    json.name whatsapp_interactive_preset.created_by.name
  else
    json.id nil
    json.name 'Former agent'
  end
end

json.permissions do
  json.update policy(whatsapp_interactive_preset).update?
  json.delete policy(whatsapp_interactive_preset).destroy?
end
