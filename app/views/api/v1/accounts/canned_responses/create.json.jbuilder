json.payload do
  json.partial! 'api/v1/models/canned_response', formats: [:json], resource: @canned_response
end
