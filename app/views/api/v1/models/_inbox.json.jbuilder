json.id resource.id
json.avatar_url resource.try(:avatar_url)
json.channel_id resource.channel_id
json.name resource.name
json.channel_type resource.channel_type
json.greeting_enabled resource.greeting_enabled
json.greeting_message resource.greeting_message
json.working_hours_enabled resource.working_hours_enabled
json.enable_email_collect resource.enable_email_collect
json.csat_survey_enabled resource.csat_survey_enabled
json.enable_auto_assignment resource.enable_auto_assignment
json.out_of_office_message resource.out_of_office_message
json.working_hours resource.weekly_schedule
json.timezone resource.timezone
json.callback_webhook_url resource.callback_webhook_url
json.allow_messages_after_resolved resource.allow_messages_after_resolved

json.tweets_enabled resource.channel.try(:tweets_enabled) if resource.twitter?

## Channel specific settings
## TODO : Clean up and move the attributes into channel sub section

## WebWidget Attributes
json.widget_color resource.channel.try(:widget_color)
json.website_url resource.channel.try(:website_url)
json.hmac_mandatory resource.channel.try(:hmac_mandatory)
json.welcome_title resource.channel.try(:welcome_title)
json.welcome_tagline resource.channel.try(:welcome_tagline)
json.web_widget_script resource.channel.try(:web_widget_script)
json.website_token resource.channel.try(:website_token)
json.selected_feature_flags resource.channel.try(:selected_feature_flags)
json.reply_time resource.channel.try(:reply_time)
if resource.web_widget?
  json.hmac_token resource.channel.try(:hmac_token)
  json.pre_chat_form_enabled resource.channel.try(:pre_chat_form_enabled)
  json.pre_chat_form_options resource.channel.try(:pre_chat_form_options)
  json.continuity_via_email resource.channel.try(:continuity_via_email)
end

## Facebook Attributes
if resource.facebook?
  json.page_id resource.channel.try(:page_id)
  json.reauthorization_required resource.channel.try(:reauthorization_required?)
end

## Twilio Attributes
json.phone_number resource.channel.try(:phone_number)
json.medium resource.channel.try(:medium) if resource.twilio?

if resource.email?
  ## Email Channel Attributes
  json.forward_to_email resource.channel.try(:forward_to_email)
  json.email resource.channel.try(:email)

  ## IMAP
  json.imap_email resource.channel.try(:imap_email)
  json.imap_password resource.channel.try(:imap_password)
  json.imap_address resource.channel.try(:imap_address)
  json.imap_port resource.channel.try(:imap_port)
  json.imap_enabled resource.channel.try(:imap_enabled)
  json.imap_enable_ssl resource.channel.try(:imap_enable_ssl)

  ## SMTP
  json.smtp_email resource.channel.try(:smtp_email)
  json.smtp_password resource.channel.try(:smtp_password)
  json.smtp_address resource.channel.try(:smtp_address)
  json.smtp_port resource.channel.try(:smtp_port)
  json.smtp_enabled resource.channel.try(:smtp_enabled)
  json.smtp_domain resource.channel.try(:smtp_domain)
end

## API Channel Attributes
if resource.api?
  json.webhook_url resource.channel.try(:webhook_url)
  json.inbox_identifier resource.channel.try(:identifier)
end
