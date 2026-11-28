json.array! @canned_responses do |canned_response|
  json.partial! 'api/v1/models/canned_response', formats: [:json], canned_response: canned_response
end
