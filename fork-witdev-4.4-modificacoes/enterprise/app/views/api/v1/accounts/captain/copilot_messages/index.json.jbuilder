json.payload do
  json.array! @copilot_messages do |message|
    json.partial! 'api/v1/models/captain/copilot_message', formats: [:json], resource: message
  end
end
