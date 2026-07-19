json.array! @internal_conversations do |conversation|
  json.partial! 'api/v1/models/internal_conversation', resource: conversation
end
