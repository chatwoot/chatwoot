json.payload do
  json.array! @copilot_messages do |message|
    json.partial! 'api/v1/models/captain/copilot_message', formats: [:json], resource: message
  end
end
json.meta do
  json.total_count @copilot_messages.total_count
  json.page @copilot_messages.current_page
end
