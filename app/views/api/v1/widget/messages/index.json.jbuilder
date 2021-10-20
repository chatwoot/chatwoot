json.array! @messages do |message|
  json.partial! 'api/v1/widget/models/_message.json.jbuilder', resource: message
end
