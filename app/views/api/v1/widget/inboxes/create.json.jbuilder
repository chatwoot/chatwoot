json.id @inbox.id
json.channel_id @inbox.channel_id
json.name @inbox.name
json.channel_type @inbox.channel_type
json.website_token @inbox.channel.try(:website_token)
