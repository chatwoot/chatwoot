json.payload do
  json.array! @assistants do |assistant|
    json.partial! 'api/v1/models/captain/assistant', formats: [:json], resource: assistant
  end
end

json.meta do
  json.total_count @assistants.count
  json.page 1 # Pagination not yet support at the moment, structure is reserved for future use
end
