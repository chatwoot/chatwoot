json.array! @agents do |agent|
  json.partial! 'api/v1/models/agent.json.jbuilder', resource: agent
end
