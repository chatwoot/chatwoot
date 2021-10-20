json.array! @conversations do |conversation|
  json.partial! 'api/v1/widget/models/_conversation.json.jbuilder', resource: conversation
end
