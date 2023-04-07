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
json.auto_assignment_config resource.auto_assignment_config
json.out_of_office_message resource.out_of_office_message
json.working_hours resource.weekly_schedule
json.timezone resource.timezone
json.callback_webhook_url resource.callback_webhook_url
json.allow_messages_after_resolved resource.allow_messages_after_resolved
json.lock_to_single_conversation resource.lock_to_single_conversation

## Channel specific settings
## TODO : Clean up and move the attributes into channel sub section

json.tweets_enabled resource.channel.try(:tweets_enabled) if resource.twitter?

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
  json.hmac_token resource.channel.try(:hmac_token) if Current.account_user&.administrator?
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
json.messaging_service_sid resource.channel.try(:messaging_service_sid)
json.phone_number resource.channel.try(:phone_number)
json.medium resource.channel.try(:medium) if resource.twilio?

if resource.email?
  ## Email Channel Attributes
  json.forward_to_email resource.channel.try(:forward_to_email)
  json.email resource.channel.try(:email)

  ## IMAP
  if Current.account_user&.administrator?
    json.imap_login resource.channel.try(:imap_login)
    json.imap_password resource.channel.try(:imap_password)
    json.imap_address resource.channel.try(:imap_address)
    json.imap_port resource.channel.try(:imap_port)
    json.imap_enabled resource.channel.try(:imap_enabled)
    json.microsoft_reauthorization resource.channel.try(:microsoft?) && resource.channel.try(:provider_config).empty?
    json.imap_enable_ssl resource.channel.try(:imap_enable_ssl)
  end

  ## SMTP
  if Current.account_user&.administrator?
    json.smtp_login resource.channel.try(:smtp_login)
    json.smtp_password resource.channel.try(:smtp_password)
    json.smtp_address resource.channel.try(:smtp_address)
    json.smtp_port resource.channel.try(:smtp_port)
    json.smtp_enabled resource.channel.try(:smtp_enabled)
    json.smtp_domain resource.channel.try(:smtp_domain)
    json.smtp_enable_ssl_tls resource.channel.try(:smtp_enable_ssl_tls)
    json.smtp_enable_starttls_auto resource.channel.try(:smtp_enable_starttls_auto)
    json.smtp_openssl_verify_mode resource.channel.try(:smtp_openssl_verify_mode)
    json.smtp_authentication resource.channel.try(:smtp_authentication)
  end
end

## API Channel Attributes
if resource.api?
  json.hmac_token resource.channel.try(:hmac_token) if Current.account_user&.administrator?
  json.webhook_url resource.channel.try(:webhook_url)
  json.inbox_identifier resource.channel.try(:identifier)
  json.additional_attributes resource.channel.try(:additional_attributes)
end

json.provider resource.channel.try(:provider)

### WhatsApp Channel
if resource.whatsapp?
  json.message_templates resource.channel.try(:message_templates)
  json.provider_config resource.channel.try(:provider_config) if Current.account_user&.administrator?
end
