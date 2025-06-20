json.array! @applications do |application|
  json.id application.id
  json.name application.name
  json.url application.url
  json.description application.description
  json.status application.status
  json.last_used_at application.last_used_at
  json.created_at application.created_at
  json.updated_at application.updated_at
end
