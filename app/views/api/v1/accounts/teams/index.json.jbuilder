json.array! @teams do |team|
  json.partial! 'api/v1/models/team', formats: [:json], resource: team
end
