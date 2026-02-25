json.payload do
  json.array! @assignable_agents do |agent|
    json.partial! 'api/v1/models/agent', formats: [:json], resource: agent
  end
end
