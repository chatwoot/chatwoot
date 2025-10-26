module Enterprise::Billing::V2::PlanCatalog
  DEFAULT_CURRENCY = 'usd'.freeze
  CREDIT_UNIT = 'Credits'.freeze

  PLAN_DEFINITIONS = [
    {
      key: :free,
      display_name: 'Chatwoot Hacker',
      base_fee: 0.0,
      monthly_credits: 0,
      config_key: 'STRIPE_HACKER_PLAN_ID',
      licensed_item_lookup_key: 'chatwoot_hacker_license_fee_v2'
    },
    {
      key: :startup,
      display_name: 'Chatwoot Startup',
      base_fee: 19.0,
      monthly_credits: 10_000,
      config_key: 'STRIPE_STARTUP_PLAN_ID',
      licensed_item_lookup_key: 'chatwoot_startup_license_fee_v2'
    },
    {
      key: :business,
      display_name: 'Chatwoot Business',
      base_fee: 39.0,
      monthly_credits: 50_000,
      config_key: 'STRIPE_BUSINESS_PLAN_ID',
      licensed_item_lookup_key: 'chatwoot_business_license_fee_v2'
    },
    {
      key: :enterprise,
      display_name: 'Chatwoot Enterprise',
      base_fee: 99.0,
      monthly_credits: 200_000,
      config_key: 'STRIPE_ENTERPRISE_PLAN_ID',
      licensed_item_lookup_key: 'chatwoot_enterprise_license_fee_v2'
    }
  ].freeze

  module_function

  def plans
    PLAN_DEFINITIONS.map do |definition|
      plan_id = plan_id_for(definition)
      build_plan(definition, plan_id)
    end
  end

  def definition_for(plan_id)
    PLAN_DEFINITIONS.each do |definition|
      return definition if plan_id_for(definition) == plan_id
    end
    nil
  end

  def monthly_credits_for(plan_id)
    definition = definition_for(plan_id)
    definition ? definition[:monthly_credits] : nil
  end

  def plan_id_for(definition)
    InstallationConfig.find_by(name: definition[:config_key])&.value
  end

  def lookup_key_for_plan(plan_id)
    # Returns the licensed_item_lookup_key for checkout sessions
    definition = definition_for(plan_id)
    definition&.dig(:licensed_item_lookup_key)
  end

  def build_plan(definition, plan_id)
    {
      id: plan_id,
      display_name: definition[:display_name],
      currency: DEFAULT_CURRENCY,
      tax_behavior: 'exclusive',
      components: build_components(definition)
    }
  end

  def build_components(definition)
    components = [service_action_component(definition), rate_card_component(definition)]
    components << license_fee_component(definition) if definition[:base_fee]&.positive?
    components
  end

  def service_action_component(definition)
    {
      type: 'service_action',
      name: 'Monthly Credits',
      credit_amount: definition[:monthly_credits],
      credit_unit: CREDIT_UNIT
    }
  end

  def rate_card_component(definition)
    {
      type: 'rate_card',
      name: 'Overage Rate',
      overage_rate: definition[:overage_rate],
      rate_unit: CREDIT_UNIT,
      meter_id: nil
    }
  end

  def license_fee_component(definition)
    {
      type: 'license_fee',
      name: 'Base Fee',
      unit_amount: definition[:base_fee].round(2)
    }
  end
end
