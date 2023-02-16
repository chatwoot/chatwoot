json.array! @messages do |message|
  json.partial! 'public/api/v1/models/message', formats: [:json], resource: message
end
