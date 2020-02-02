json.payload do
  json.success true
  json.data do
    json.id @resource.id
    json.provider @resource.provider
    json.uid @resource.uid
    json.name @resource.name
    json.nickname @resource.nickname
    json.email @resource.email
    json.account_id @resource.account_id
    json.pubsub_token @resource.pubsub_token
    json.role @resource.role
    json.inviter_id @resource.inviter_id
    json.confirmed @resource.confirmed?
    json.avatar_url @resource.avatar_url
  end
end
