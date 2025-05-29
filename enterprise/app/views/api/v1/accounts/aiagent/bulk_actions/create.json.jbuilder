json.array! @responses do |response|
  json.partial! 'api/v1/models/aiagent/assistant_response', formats: [:json], resource: response
end
