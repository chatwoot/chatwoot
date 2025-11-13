# frozen_string_literal: true

json.payload do
  json.array! @scheduled_messages do |scheduled_message|
    json.partial! 'api/v1/models/scheduled_message', scheduled_message: scheduled_message
  end
end

json.meta do
  json.current_page @scheduled_messages.current_page
  json.total_pages @scheduled_messages.total_pages
  json.total_count @scheduled_messages.total_count
end
