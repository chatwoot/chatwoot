# Resolves billing plans from the provider-specific installation configuration.
module Enterprise::Billing::PlanConfiguration
  CLOUD_PLANS_CONFIG = 'CHATWOOT_CLOUD_PLANS'.freeze
  SHOPIFY_PLANS_CONFIG = Enterprise::Billing::ShopifyPlanConfiguration::CONFIG_NAME
  PROVIDER_CONFIGS = {
    'stripe' => CLOUD_PLANS_CONFIG,
    'shopify' => SHOPIFY_PLANS_CONFIG
  }.freeze
  class InvalidConfiguration < StandardError; end
  class UnknownPlan < StandardError; end

  module_function

  def plans(provider: Account::DEFAULT_BILLING_PROVIDER)
    config_name = PROVIDER_CONFIGS.fetch(provider.to_s) do
      raise ArgumentError, "Unsupported billing provider: #{provider}"
    end
    configured_plans = if provider.to_s == 'shopify'
                         InstallationConfig.find_by!(name: config_name).value
                       else
                         InstallationConfig.find_by(name: config_name)&.value || []
                       end

    provider.to_s == 'shopify' ? Enterprise::Billing::ShopifyPlanConfiguration.normalize(configured_plans) : configured_plans
  end

  def plans_for(account)
    plans(provider: account.billing_provider)
  end

  def default_plan(account = nil)
    provider = account&.billing_provider || Account::DEFAULT_BILLING_PROVIDER
    plans(provider: provider).first
  end

  def current_plan(account)
    plan_name = account.custom_attributes['plan_name']
    return if plan_name.blank?

    plans_for(account).find { |plan| plan['name'].casecmp?(plan_name.to_s) }
  end

  def current_plan!(account)
    current_plan(account) || raise(UnknownPlan, "Unknown #{account.billing_provider} plan for account #{account.id}")
  end

  def find_shopify_plan_by_handle(handle)
    return if handle.blank?

    plans(provider: 'shopify').find { |plan| plan['handle'] == handle }
  end

  # Stripe-specific helpers. A plan's `price_ids` may be a currency-keyed Hash,
  # or a legacy Array (treated as usd).
  # Handles both shapes during migration; once all configs are currency-keyed Hashes, drop the Array branch.
  def price_ids_by_currency(plan)
    raw = plan && plan['price_ids']
    case raw
    when Hash then raw.transform_keys { |key| Enterprise::Billing::Currencies.normalize(key) }
    when Array then { Enterprise::Billing::Currencies::DEFAULT => raw }
    else {}
    end
  end

  # Price id for `plan` in `currency`, falling back to usd then any configured price.
  # The multi-step fallback is migration-era safety; once configs settle on one format we can simplify this.
  def price_id_for(plan, currency)
    by_currency = price_ids_by_currency(plan)
    code = Enterprise::Billing::Currencies.to_supported(currency)

    (by_currency[code].presence ||
     by_currency[Enterprise::Billing::Currencies::DEFAULT].presence ||
     by_currency.values.flatten.compact).first
  end

  # Match by product id, not price id: production has prices that aren't enumerated
  # in our config but share a product, so product matching still resolves the plan.
  def plan_contains_product_id?(plan, product_id)
    Array(plan && plan['product_id']).include?(product_id)
  end

  def find_plan_by_product_id(product_id)
    plans.find { |plan| plan_contains_product_id?(plan, product_id) }
  end
end
