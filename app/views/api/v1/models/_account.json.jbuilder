json.auto_resolve_duration resource.auto_resolve_duration
json.created_at resource.created_at
if resource.custom_attributes.present?
  json.custom_attributes do
    json.plan_name resource.custom_attributes['plan_name']
    json.subscribed_quantity resource.custom_attributes['subscribed_quantity']
    json.subscription_status resource.custom_attributes['subscription_status']
    json.subscription_ends_on resource.custom_attributes['subscription_ends_on']
    json.industry resource.custom_attributes['industry'] if resource.custom_attributes['industry'].present?
    json.call_config resource.custom_attributes['call_config'] if resource.custom_attributes['call_config'].present?
    json.calling_settings resource.custom_attributes['calling_settings'] if resource.custom_attributes['calling_settings'].present?
    json.show_label_to_agent resource.custom_attributes['show_label_to_agent'] if resource.custom_attributes['show_label_to_agent'].present?
    json.show_reports_to_agent resource.custom_attributes['show_reports_to_agent'] if resource.custom_attributes['show_reports_to_agent'].present?
    if resource.custom_attributes['restrict_agent_assignment'].present?
      json.restrict_agent_assignment resource.custom_attributes['restrict_agent_assignment']
    end
    if resource.custom_attributes['hide_delete_message_button_for_agent'].present?
      json.hide_delete_message_button_for_agent resource.custom_attributes['hide_delete_message_button_for_agent']
    end
    if resource.custom_attributes['show_only_customer_message_timestamp'].present?
      json.show_only_customer_message_timestamp resource.custom_attributes['show_only_customer_message_timestamp']
    end
    json.contact_masking resource.custom_attributes['contact_masking'] if resource.custom_attributes['contact_masking'].present?
    json.company_size resource.custom_attributes['company_size'] if resource.custom_attributes['company_size'].present?
    json.timezone resource.custom_attributes['timezone'] if resource.custom_attributes['timezone'].present?
    json.logo resource.custom_attributes['logo'] if resource.custom_attributes['logo'].present?
    json.onboarding_step resource.custom_attributes['onboarding_step'] if resource.custom_attributes['onboarding_step'].present?
    if resource.custom_attributes['enable_contact_assignment'].present?
      json.enable_contact_assignment resource.custom_attributes['enable_contact_assignment']
    end
    json.instagram_dm_message resource.instagram_dm_message if @account.instagram_inbox?
  end
end
json.domain @account.domain
json.features @account.enabled_features
json.id @account.id
json.locale @account.locale
json.name @account.name
json.support_email @account.support_email
json.status @account.status
json.cache_keys @account.cache_keys
json.has_instagram_inbox @account.instagram_inbox?
