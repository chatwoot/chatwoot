json.array! @conversations do |conversation|
  json.partial! 'api/v1/models/conversation.json.jbuilder', conversation: conversation
end
