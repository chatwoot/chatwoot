json.partial! 'conversation', conversation: @conversation

json.messages do
  json.array! @conversation.messages do |message|
    json.partial! 'api/v1/models/widget_message', resource: message
  end
end
