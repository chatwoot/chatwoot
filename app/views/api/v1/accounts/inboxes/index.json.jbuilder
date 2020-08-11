json.payload do
  json.array! @inboxes do |inbox|
    json.partial! 'api/v1/models/inbox.json.jbuilder', resource: inbox
  end
end
