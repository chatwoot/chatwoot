json.array! @response_sources do |response_source|
  json.partial! 'api/v1/models/response_source', formats: [:json], resource: response_source
end
