json.source_id resource.source_id
json.is_widget_authenticated resource.hmac_verified

json.inbox do
  json.partial! 'api/v1/models/inbox_slim', formats: [:json], resource: resource.inbox
end
