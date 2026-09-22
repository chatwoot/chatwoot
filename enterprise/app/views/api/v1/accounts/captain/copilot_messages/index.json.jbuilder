json.payload do
  json.array! @copilot_messages do |message|
    json.partial! 'api/v1/models/captain/copilot_message', formats: [:json], resource: message
  end
end

json.meta do
  json.page @copilot_message_page.current_page
  json.total_count @copilot_message_page.total_count
  json.next_page @copilot_message_page.next_page
end
