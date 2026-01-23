json.payload do
  json.array! @agents do |agent|
    json.partial! 'api/v1/models/agent', formats: [:json], resource: agent
    inbox_member = @inbox_members_map[agent.id]
    json.assignment_eligible inbox_member&.assignment_eligible
  end
end
