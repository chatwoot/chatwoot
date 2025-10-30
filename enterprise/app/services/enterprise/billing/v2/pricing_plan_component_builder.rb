class Enterprise::Billing::V2::PricingPlanComponentBuilder < Enterprise::Billing::V2::BaseService
  include Enterprise::Billing::Concerns::StripeV2ClientHelper

  def add_license_fee_component(plan, config)
    licensed_item = create_licensed_item(
      display_name: config[:licensed_item_display_name],
      lookup_key: config[:lookup_key],
      unit_label: config[:licensed_item_unit_label]
    )

    license_fee = create_license_fee(
      display_name: config[:license_fee_display_name],
      unit_amount: config[:license_fee_amount],
      licensed_item_id: licensed_item.id,
      lookup_key: config[:lookup_key]
    )

    add_component(
      plan_id: plan.id,
      type: 'license_fee',
      data: { id: license_fee.id, version: license_fee.latest_version },
      lookup_key: config[:lookup_key]
    )
  end

  def add_service_action_component(plan, config, cpu)
    action = create_service_action(
      lookup_key: config[:service_action_lookup_key],
      credit_amount: config[:monthly_credit_amount],
      cpu_id: cpu.id
    )

    add_component(
      plan_id: plan.id,
      type: 'service_action',
      data: { id: action.id },
      lookup_key: config[:service_action_lookup_key]
    )

    action
  end

  def add_rate_card_component(plan, config, meter, cpu)
    card = create_rate_card(display_name: config[:rate_card_display_name])

    item = create_metered_item(
      display_name: config[:metered_item_display_name],
      lookup_key: config[:metered_item_lookup_key],
      meter_id: meter.id
    )

    add_rate(card_id: card.id, item_id: item.id, cpu_id: cpu.id, value: config[:rate_value] || 1)

    add_component(
      plan_id: plan.id,
      type: 'rate_card',
      data: { id: card.id, version: card.latest_version },
      lookup_key: config[:metered_item_lookup_key]
    )

    card
  end

  private

  def create_licensed_item(display_name:, lookup_key:, unit_label:)
    super({ display_name: display_name, lookup_key: lookup_key, unit_label: unit_label })
  end

  def create_license_fee(display_name:, unit_amount:, licensed_item_id:, lookup_key:)
    super({
      display_name: display_name,
      currency: 'usd',
      service_interval: 'month',
      service_interval_count: 1,
      tax_behavior: 'exclusive',
      unit_amount: unit_amount.to_s,
      licensed_item: licensed_item_id,
      lookup_key: lookup_key
    })
  end

  def create_service_action(lookup_key:, credit_amount:, cpu_id:)
    super(service_action_params(lookup_key, credit_amount, cpu_id))
  end

  def service_action_params(lookup_key, credit_amount, cpu_id)
    {
      lookup_key: lookup_key,
      service_interval: 'month',
      service_interval_count: 1,
      type: 'credit_grant',
      credit_grant: credit_grant_config(credit_amount, cpu_id)
    }
  end

  def credit_grant_config(credit_amount, cpu_id)
    {
      name: 'Monthly Credits',
      amount: {
        type: 'custom_pricing_unit',
        custom_pricing_unit: { id: cpu_id, value: credit_amount.to_s }
      },
      expiry_config: { type: 'end_of_service_period' },
      applicability_config: { scope: { price_type: 'metered' } }
    }
  end

  def create_rate_card(display_name:)
    super({
      display_name: display_name,
      currency: 'usd',
      service_interval: 'month',
      service_interval_count: 1,
      tax_behavior: 'exclusive'
    })
  end

  def create_metered_item(display_name:, lookup_key:, meter_id:)
    super({ display_name: display_name, lookup_key: lookup_key, meter: meter_id })
  end

  def add_rate(card_id:, item_id:, cpu_id:, value:)
    add_rate_to_card(card_id, {
                       metered_item: item_id,
                       custom_pricing_unit_amount: { id: cpu_id, value: value.to_s }
                     })
  end

  def add_component(plan_id:, type:, data:, lookup_key:)
    params = case type
             when 'license_fee'
               { type: 'license_fee', license_fee: data, lookup_key: lookup_key }
             when 'service_action'
               { type: 'service_action', service_action: data, lookup_key: lookup_key }
             when 'rate_card'
               { type: 'rate_card', rate_card: data, lookup_key: lookup_key }
             end

    add_pricing_plan_component(plan_id, params)
  end
end
