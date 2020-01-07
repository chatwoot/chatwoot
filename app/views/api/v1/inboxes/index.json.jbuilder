json.payload do
  json.array! @inboxes do |inbox|
    json.id inbox.id
    json.channel_id inbox.channel_id
    json.name inbox.name
    json.channel_type inbox.channel_type
    json.avatar_url inbox.channel.try(:avatar_url)
    json.page_id inbox.channel.try(:page_id)
    json.widget_color inbox.channel.try(:widget_color)
    json.website_token inbox.channel.try(:website_token)
  end
end
