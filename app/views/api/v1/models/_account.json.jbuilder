json.id resource.id
json.name resource.name
json.locale resource.locale
json.domain resource.domain
json.custom_email_domain_enabled resource.custom_email_domain_enabled
json.support_email resource.support_email
json.features resource.all_features
json.auto_resolve_duration resource.auto_resolve_duration
json.created_at resource.created_at
if ChatwootApp.chatwoot_saas?
  json.billing_status resource.account_billing_subscriptions.present? ? "subscribed" : "trial"
end