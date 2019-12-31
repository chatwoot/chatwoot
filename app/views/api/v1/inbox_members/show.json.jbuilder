json.payload do
  json.array! @agents do |agent|
    json.user_id agent.id
    json.name agent.name
  end
end
