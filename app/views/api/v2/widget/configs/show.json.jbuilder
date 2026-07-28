json.channel_config do
  json.allow_messages_after_resolved @web_widget.inbox.allow_messages_after_resolved
  json.avatar_url @web_widget.inbox.avatar_url
  json.csat_survey_enabled @web_widget.inbox.csat_survey_enabled
  json.disable_branding @web_widget.inbox.account.feature_enabled?('disable_branding')
  json.enabled_features @web_widget.selected_feature_flags
  json.enabled_languages available_locales_with_name
  json.end_conversation_enabled @web_widget.end_conversation?
  json.locale @web_widget.account.locale
  json.lock_to_single_conversation @web_widget.inbox.lock_to_single_conversation
  json.out_of_office_message @web_widget.inbox.out_of_office_message
  json.pre_chat_form_enabled @web_widget.pre_chat_form_enabled
  json.pre_chat_form_options @web_widget.pre_chat_form_options
  json.reply_time @web_widget.reply_time
  json.timezone @web_widget.inbox.timezone
  json.utc_offset ActiveSupport::TimeZone[@web_widget.inbox.timezone].now.formatted_offset
  json.website_name @web_widget.inbox.name
  json.website_token @web_widget.website_token
  json.welcome_tagline @web_widget.welcome_tagline
  json.welcome_title @web_widget.welcome_title
  json.widget_color @web_widget.widget_color
  json.working_hours @web_widget.inbox.working_hours
  json.working_hours_enabled @web_widget.inbox.working_hours_enabled
end

if @web_widget.inbox.portal.present?
  json.portal do
    json.slug @web_widget.inbox.portal.slug
    json.name @web_widget.inbox.portal.name
    json.custom_domain @web_widget.inbox.portal.custom_domain
    json.default_locale @web_widget.inbox.portal.default_locale
    json.config @web_widget.inbox.portal.config
  end
else
  json.portal nil
end

json.ai_agent @ai_agent

json.announcements @announcements do |announcement|
  json.id announcement.id
  json.title announcement.title
  json.message announcement.message
  json.level announcement.level
  json.action_url announcement.action_url
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
