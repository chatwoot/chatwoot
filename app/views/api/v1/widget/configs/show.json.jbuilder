json.website_channel_config do
  json.api_host ENV.fetch('FRONTEND_URL', nil)
  json.avatar_url @web_widget.inbox.avatar_url
  json.locale @web_widget.account.locale
  json.website_name @web_widget.inbox.name
  json.website_token @web_widget.website_token
  json.widget_color @web_widget.widget_color
  json.widget_position @web_widget.widget_position
  json.widget_type @web_widget.widget_type
  json.launcher_title @web_widget.launcher_title
  json.avatar_name @web_widget.avatar_name
end

json.global_config @global_config
