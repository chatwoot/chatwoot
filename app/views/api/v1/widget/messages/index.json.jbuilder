json.array! @messages do |message|
  json.partial! 'api/v1/widget/models/message.json.jbuilder', resource: message
end
