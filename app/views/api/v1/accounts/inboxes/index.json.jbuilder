json.payload do
  json.array! @inboxes do |inbox|
    json.id inbox.id
    json.channel_id inbox.channel_id
    json.name inbox.name
    json.channel_type inbox.channel_type
    json.avatar_url inbox.try(:avatar_url)
    json.page_id inbox.channel.try(:page_id)
    json.widget_color inbox.channel.try(:widget_color)
    json.website_url inbox.channel.try(:website_url)
    json.welcome_title inbox.channel.try(:welcome_title)
    json.welcome_tagline inbox.channel.try(:welcome_tagline)
    json.agent_away_message inbox.channel.try(:agent_away_message)
    json.enable_auto_assignment inbox.enable_auto_assignment
    json.web_widget_script inbox.channel.try(:web_widget_script)
    json.phone_number inbox.channel.try(:phone_number)
  end
end
