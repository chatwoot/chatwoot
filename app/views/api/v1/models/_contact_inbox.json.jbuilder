json.source_id resource.source_id
json.inbox do
  json.partial! 'api/v1/models/inbox.json.jbuilder', resource: resource.inbox
end
