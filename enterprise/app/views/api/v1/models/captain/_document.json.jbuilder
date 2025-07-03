json.account_id resource.account_id
json.assistant do
  json.partial! 'api/v1/models/captain/assistant', formats: [:json], resource: resource.assistant
end
json.content resource.content
json.created_at resource.created_at.to_i
json.external_link resource.external_link
json.id resource.id
json.name resource.name
json.status resource.status
json.source_type resource.source_type
json.updated_at resource.updated_at.to_i

# Include file information for PDF uploads
if resource.file.attached?
  json.file do
    json.url url_for(resource.file)
    json.filename resource.file.filename
    json.content_type resource.file.content_type
    json.size resource.file.byte_size
  end
end
