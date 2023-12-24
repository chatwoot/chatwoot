json.array! @conversation.messages.csat do |message|
  json.partial! 'public/api/v1/models/csat_survey', formats: [:json], resource: message
end