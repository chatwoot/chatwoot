json.website_channel_config do
  json.allow_messages_after_resolved @web_widget.inbox.allow_messages_after_resolved
  json.api_host ENV.fetch('FRONTEND_URL', nil)
  json.auth_token @token
  json.avatar_url @web_widget.inbox.avatar_url
  json.csat_survey_enabled @web_widget.inbox.csat_survey_enabled
  json.disable_branding @web_widget.inbox.account.feature_enabled?('disable_branding')
  json.enabled_features @web_widget.selected_feature_flags
  json.enabled_languages available_locales_with_name
  json.locale @web_widget.account.locale
  json.out_of_office_message @web_widget.inbox.out_of_office_message
  json.portal @web_widget.inbox.portal
  json.pre_chat_form_enabled @web_widget.pre_chat_form_enabled
  json.pre_chat_form_options @web_widget.pre_chat_form_options
  json.reply_time @web_widget.reply_time
  json.timezone @web_widget.inbox.timezone
  json.utc_off_set ActiveSupport::TimeZone[@web_widget.inbox.timezone].now.formatted_offset
  json.website_name @web_widget.inbox.name
  json.website_token @web_widget.website_token
  json.welcome_tagline @web_widget.welcome_tagline
  json.welcome_title @web_widget.welcome_title
  json.widget_color @web_widget.widget_color
  json.working_hours @web_widget.inbox.working_hours
  json.working_hours_enabled @web_widget.inbox.working_hours_enabled
end

json.contact do
  json.email @contact.email
  json.id @contact.id
  json.identifier @contact.identifier
  json.name @contact.name
  json.phone_number @contact.phone_number
  json.pubsub_token @contact_inbox.pubsub_token
end

json.global_config @global_config
