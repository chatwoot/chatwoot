json.settings resource.settings
json.created_at resource.created_at
if resource.custom_attributes.present?
  json.custom_attributes do
    json.plan_name resource.custom_attributes['plan_name']
    json.subscribed_quantity resource.custom_attributes['subscribed_quantity']
    json.subscription_status resource.custom_attributes['subscription_status']
    json.subscription_ends_at resource.custom_attributes['subscription_ends_at']
    json.subscription_cancelled_at resource.custom_attributes['subscription_cancelled_at'] if resource.custom_attributes['subscription_cancelled_at'].present?
    json.stripe_subscription_id resource.custom_attributes['stripe_subscription_id'] if resource.custom_attributes['stripe_subscription_id'].present?
    json.stripe_plan_id resource.custom_attributes['stripe_plan_id'] if resource.custom_attributes['stripe_plan_id'].present?
    json.stripe_billing_version resource.custom_attributes['stripe_billing_version'] if resource.custom_attributes['stripe_billing_version'].present?
    json.stripe_customer_id resource.custom_attributes['stripe_customer_id'] if resource.custom_attributes['stripe_customer_id'].present?
    if resource.custom_attributes['pending_stripe_pricing_plan_id'].present?
      json.pending_stripe_pricing_plan_id resource.custom_attributes['pending_stripe_pricing_plan_id']
    end
    if resource.custom_attributes['pending_subscription_quantity'].present?
      json.pending_subscription_quantity resource.custom_attributes['pending_subscription_quantity']
    end
    json.stripe_pricing_plan_id resource.custom_attributes['stripe_pricing_plan_id'] if resource.custom_attributes['stripe_pricing_plan_id'].present?
    json.next_billing_date resource.custom_attributes['next_billing_date'] if resource.custom_attributes['next_billing_date'].present?
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
