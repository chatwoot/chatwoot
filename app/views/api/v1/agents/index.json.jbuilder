json.array! @agents do |agent|
  json.account_id agent.account.id
  json.availability_status agent.availability_status
  json.confirmed agent.confirmed?
  json.email agent.email
  json.id agent.id
  json.name agent.name
  json.role agent.role
  json.thumbnail agent.avatar_url
end
