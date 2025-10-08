class Enterprise::Billing::V2::PricingPlanService < Enterprise::Billing::V2::BaseService
  def create_custom_pricing_unit(display_name:, lookup_key:)
    Stripe::V2::Billing::CustomPricingUnit.create(
      { display_name: display_name, lookup_key: lookup_key },
      { api_key: ENV.fetch('STRIPE_SECRET_KEY', nil), stripe_version: '2025-08-27.preview' }
    )
  end

  def create_meter(display_name:, event_name:)
    Stripe::Billing::Meter.create(
      {
        display_name: display_name,
        event_name: event_name,
        default_aggregation: { formula: 'sum' },
        customer_mapping: { type: 'by_id', event_payload_key: 'stripe_customer_id' },
        value_settings: { event_payload_key: 'value' }
      },
      { api_key: ENV.fetch('STRIPE_SECRET_KEY', nil), stripe_version: '2025-08-27.preview' }
    )
  end

  def create_pricing_plan(display_name:, currency: 'usd', tax_behavior: 'exclusive')
    Stripe::V2::Billing::PricingPlan.create(
      { display_name: display_name, currency: currency, tax_behavior: tax_behavior },
      { api_key: ENV.fetch('STRIPE_SECRET_KEY', nil), stripe_version: '2025-08-27.preview' }
    )
  end

  def create_complete_pricing_plan(config)
    cpu = create_custom_pricing_unit(
      display_name: config[:cpu_display_name],
      lookup_key: config[:cpu_lookup_key]
    )

    meter = create_meter(
      display_name: config[:meter_display_name],
      event_name: config[:meter_event_name]
    )

    plan = create_pricing_plan(display_name: config[:plan_display_name])

    builder = component_builder

    builder.add_license_fee_component(plan, config) if config[:include_license_fee]
    service_action = builder.add_service_action_component(plan, config, cpu)
    rate_card = builder.add_rate_card_component(plan, config, meter, cpu)

    build_plan_result(plan, cpu, meter, rate_card, service_action)
  rescue StandardError => e
    { success: false, message: e.message }
  end

  private

  def component_builder
    @component_builder ||= Enterprise::Billing::V2::PricingPlanComponentBuilder.new(account: account)
  end

  def build_plan_result(plan, cpu, meter, rate_card, service_action)
    {
      success: true,
      pricing_plan: plan,
      custom_pricing_unit: cpu,
      meter: meter,
      rate_card: rate_card,
      service_action: service_action
    }
  end
end
