if @team_member
  json.partial! 'api/v1/models/agent.json.jbuilder', resource: @team_member
elsif @team_members.present?
  json.array! @team_members do |team_member|
    json.partial! 'api/v1/models/agent.json.jbuilder', resource: team_member
  end
end
