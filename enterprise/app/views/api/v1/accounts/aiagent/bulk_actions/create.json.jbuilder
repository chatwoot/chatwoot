json.array! @responses do |response|
  json.partial! 'api/v1/models/aiagent/topic_response', formats: [:json], resource: response
end
