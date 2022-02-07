json.chatwoot_website_channel do
  json.avatar_url @web_widget.inbox.avatar_url
  json.has_a_connected_agent_bot @web_widget.inbox.agent_bot&.name
  json.locale @web_widget.account.locale
  json.website_name @web_widget.inbox.name
  json.website_token @web_widget.website_token
  json.welcome_tagline @web_widget.welcome_tagline
  json.welcome_title @web_widget.welcome_title
  json.widget_color @web_widget.widget_color
  json.enabled_features @web_widget.selected_feature_flags
  json.enabled_languages available_locales_with_name
  json.reply_time @web_widget.reply_time
  json.pre_chat_form_enabled @web_widget.pre_chat_form_enabled
  json.pre_chat_form_options @web_widget.pre_chat_form_options
  json.working_hours_enabled @web_widget.inbox.working_hours_enabled
  json.csat_survey_enabled @web_widget.inbox.csat_survey_enabled
  json.working_hours @web_widget.inbox.working_hours
  json.out_of_office_message @web_widget.inbox.out_of_office_message
  json.utc_off_set ActiveSupport::TimeZone[@web_widget.inbox.timezone].now.formatted_offset
end
json.chatwoot_widget_defaults do
  json.use_inbox_avatar_for_bot ActiveModel::Type::Boolean.new.cast(ENV.fetch('USE_INBOX_AVATAR_FOR_BOT', false))
end
json.contact do
  json.pubsub_token @contact_inbox.pubsub_token
end
json.auth_token @token
json.global_config @global_config
