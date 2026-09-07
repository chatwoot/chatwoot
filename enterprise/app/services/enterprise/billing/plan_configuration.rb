# Resolves Stripe price ids from CHATWOOT_CLOUD_PLANS per currency.
# A plan's `price_ids` may be a currency-keyed Hash, or a legacy Array (treated as usd).
module Enterprise::Billing::PlanConfiguration
  CLOUD_PLANS_CONFIG = 'CHATWOOT_CLOUD_PLANS'.freeze

  module_function

  def plans
    InstallationConfig.find_by(name: CLOUD_PLANS_CONFIG)&.value || []
  end

  def default_plan
    plans.first
  end

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
