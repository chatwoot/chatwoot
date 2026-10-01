json.billing_provider account.billing_provider
json.subscription_status account.custom_attributes['subscription_status']
shopify_integration = Shopify::FeatureGate.enabled?(account: account)
json.shopify_integration shopify_integration
if shopify_integration && account.billing_provider == 'shopify'
  json.shopify_shop_domain account.hooks.find_by(app_id: 'shopify', status: 'enabled')&.reference_id
end
