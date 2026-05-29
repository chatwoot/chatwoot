json.data do
  json.partial! 'api/v1/models/user', formats: [:json], resource: resource, include_access_tokens: true
end
