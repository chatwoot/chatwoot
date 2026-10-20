json.data do
  json.partial! 'api/v1/models/user', formats: [:json], resource: resource, authenticated_resource: true
end
