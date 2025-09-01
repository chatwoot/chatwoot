json.array! @message_templates do |message_template|
  json.partial! 'message_template', formats: [:json], message_template: message_template
end