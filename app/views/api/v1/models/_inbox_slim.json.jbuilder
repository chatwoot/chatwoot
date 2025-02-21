json.id resource.id
json.avatar_url resource.try(:avatar_url)
json.channel_id resource.channel_id
json.name resource.name
json.channel_type resource.channel_type

if resource.email?
  ## Email Channel Attributes
  json.forward_to_email resource.channel.try(:forward_to_email)
  json.email resource.channel.try(:email)
end
