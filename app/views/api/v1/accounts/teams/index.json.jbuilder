json.array! @teams do |team|
  json.partial! 'api/v1/models/team.json.jbuilder', resource: team
end
