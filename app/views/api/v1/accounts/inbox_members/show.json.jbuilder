json.payload do
  json.array! @agents do |agent|
    json.partial! 'api/v1/models/user.json.jbuilder', resource: agent
  end
end
