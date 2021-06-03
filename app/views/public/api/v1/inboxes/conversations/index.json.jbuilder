json.array! @conversations do |conversation|
  json.partial! 'public/api/v1/models/conversation.json.jbuilder', resource: conversation
end
