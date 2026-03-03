json.array! @message_templates do |message_template|
  json.partial! 'api/v1/models/message_template', formats: [:json], resource: message_template
end
