json.payload do
  json.array! @inboxes do |inbox|
    json.partial! 'api/v1/models/inbox', formats: [:json], resource: inbox
  end
end

json.meta do
  json.total_count @inboxes.count
  json.page 1
end
