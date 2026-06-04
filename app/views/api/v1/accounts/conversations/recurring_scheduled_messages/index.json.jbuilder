json.payload do
  json.array! @recurring_scheduled_messages do |recurring_scheduled_message|
    json.partial! 'api/v1/models/recurring_scheduled_message', recurring_scheduled_message: recurring_scheduled_message
  end
end
