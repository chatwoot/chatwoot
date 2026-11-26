json.merge! @conversation.widget_push_event_data
json.messages do
  json.array! @conversation.messages.chat do |message|
    json.partial! 'api/v1/models/widget_message', resource: message
  end
end
json.custom_attributes @conversation.custom_attributes
