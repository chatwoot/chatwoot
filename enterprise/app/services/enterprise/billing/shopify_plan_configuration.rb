module Enterprise::Billing::ShopifyPlanConfiguration
  CONFIG_NAME = 'CHATWOOT_SHOPIFY_PLANS'.freeze
  REQUIRED_LIMITS = %w[agents inboxes].freeze
  LIMITS = %w[agents inboxes emails captain_documents captain_responses].freeze

  module_function

  def normalize(configured_plans)
    raise_invalid!("#{CONFIG_NAME} must be an array") unless configured_plans.is_a?(Array)

    normalized_plans = configured_plans.map.with_index do |plan, index|
      raise_invalid!("#{CONFIG_NAME}[#{index}] must be an object") unless plan.is_a?(Hash)

      plan.deep_stringify_keys
    end

    validate!(normalized_plans)
    normalized_plans
  end

  def validate!(plans)
    raise_invalid!("#{CONFIG_NAME} must contain at least one plan") if plans.empty?

    plans.each.with_index { |plan, index| validate_plan!(plan, index) }
    validate_unique_field!(plans, 'name')
    validate_unique_field!(plans, 'handle')
  end

  def validate_plan!(plan, index)
    prefix = "#{CONFIG_NAME}[#{index}]"
    raise_invalid!("#{prefix}.name is required") unless plan['name'].is_a?(String) && plan['name'].present?
    raise_invalid!("#{prefix}.handle is required") unless plan['handle'].is_a?(String) && plan['handle'].present?
    raise_invalid!("#{prefix}.features must be an array") unless plan['features'].is_a?(Array)
    raise_invalid!("#{prefix}.limits must be an object") unless plan['limits'].is_a?(Hash)

    validate_features!(plan['features'], prefix)
    validate_limits!(plan['limits'], prefix)
  end

  def validate_features!(features, prefix)
    known_features = Featurable::FEATURE_LIST.pluck('name')
    invalid_features = features.reject { |feature| feature.is_a?(String) && known_features.include?(feature) }
    raise_invalid!("#{prefix}.features contains unknown features") if invalid_features.present?

    return unless features.include?(Shopify::FeatureGate::ACCOUNT_FEATURE)

    raise_invalid!("#{prefix}.features cannot manage #{Shopify::FeatureGate::ACCOUNT_FEATURE}")
  end

  def validate_limits!(limits, prefix)
    raise_invalid!("#{prefix}.limits contains unknown limits") if (limits.keys - LIMITS).present?
    raise_invalid!("#{prefix}.limits is missing required limits") if (REQUIRED_LIMITS - limits.keys).present?
    return if limits.values.all? { |value| value.is_a?(Integer) && value >= 0 }

    raise_invalid!("#{prefix}.limits must contain non-negative integers")
  end

  def validate_unique_field!(plans, field)
    values = plans.pluck(field).map(&:downcase)
    raise_invalid!("#{CONFIG_NAME} contains duplicate #{field} values") unless values.uniq.length == values.length
  end

  def raise_invalid!(message)
    raise Enterprise::Billing::PlanConfiguration::InvalidConfiguration, message
  end
end
