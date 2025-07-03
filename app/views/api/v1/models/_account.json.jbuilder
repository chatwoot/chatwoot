json.settings resource.settings
json.created_at resource.created_at
if resource.custom_attributes.present?
  json.custom_attributes do
    json.plan_name resource.custom_attributes['plan_name']
    json.subscribed_quantity resource.custom_attributes['subscribed_quantity']
    json.subscription_status resource.custom_attributes['subscription_status']
    json.subscription_ends_on resource.custom_attributes['subscription_ends_on']
    json.industry resource.custom_attributes['industry'] if resource.custom_attributes['industry'].present?
    json.company_size resource.custom_attributes['company_size'] if resource.custom_attributes['company_size'].present?
    json.timezone resource.custom_attributes['timezone'] if resource.custom_attributes['timezone'].present?
    json.logo resource.custom_attributes['logo'] if resource.custom_attributes['logo'].present?
    json.onboarding_step resource.custom_attributes['onboarding_step'] if resource.custom_attributes['onboarding_step'].present?
    json.marked_for_deletion_at resource.custom_attributes['marked_for_deletion_at'] if resource.custom_attributes['marked_for_deletion_at'].present?
    if resource.custom_attributes['marked_for_deletion_reason'].present?
      json.marked_for_deletion_reason resource.custom_attributes['marked_for_deletion_reason']
    end
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
