json.source_id resource.source_id
json.inbox do
  json.partial! 'api/v1/models/inbox', formats: [:json], resource: resource.inbox
end
