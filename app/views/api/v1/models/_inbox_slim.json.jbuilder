json.id resource.id
json.avatar_url resource.try(:avatar_url)
json.channel_id resource.channel_id
json.name resource.name
json.channel_type resource.channel_type
json.provider resource.channel.try(:provider)

# Fix me: this is for the new conversation modal to work,
# Potentially refactor this later.
json.email resource.channel.try(:email) if resource.email?
json.phone_number resource.channel.try(:phone_number)
json.medium resource.channel.try(:medium) if resource.twilio?
json.message_templates resource.channel.try(:message_templates) if resource.whatsapp?
