json.array! @conversations do |conversation|
  json.partial! 'api/v1/widget/models/conversation.json.jbuilder', resource: conversation
end
