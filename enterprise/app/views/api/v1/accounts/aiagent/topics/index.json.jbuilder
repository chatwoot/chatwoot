json.payload do
  json.array! @topics do |topic|
    json.partial! 'api/v1/models/aiagent/topic', formats: [:json], resource: topic
  end
end

json.meta do
  json.total_count @topics.count
  json.page 1 # Pagination not yet support at the moment, structure is reserved for future use
end
