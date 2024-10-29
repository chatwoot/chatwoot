json.array! @resources do |resource|
  json.partial! 'platform/api/v1/models/agent_bot', formats: [:json], resource: resource.permissible
end
