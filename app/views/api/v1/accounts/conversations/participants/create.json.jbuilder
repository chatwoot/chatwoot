json.array! @participants do |participant|
  json.partial! 'api/v1/models/agent.json.jbuilder', resource: participant.user
end
