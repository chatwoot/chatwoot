json.payload do
  json.array! @assignable_agents_payload do |resource|
    if resource.is_a?(AgentBot)
      json.partial! 'api/v1/models/assignable_agent_bot', formats: [:json], resource: resource
    else
      json.partial! 'api/v1/models/agent', formats: [:json], resource: resource
    end
  end
end
