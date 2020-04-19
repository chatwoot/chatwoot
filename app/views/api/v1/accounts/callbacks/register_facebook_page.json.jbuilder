json.id @facebook_inbox.id
json.channel_id @facebook_inbox.channel_id
json.name @facebook_inbox.name
json.channel_type @facebook_inbox.channel_type
json.avatar_url @facebook_inbox.try(:avatar_url)
json.page_id @facebook_inbox.channel.try(:page_id)
json.enable_auto_assignment @facebook_inbox.enable_auto_assignment
