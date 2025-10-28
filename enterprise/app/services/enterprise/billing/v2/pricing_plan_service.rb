class Enterprise::Billing::V2::PricingPlanService < Enterprise::Billing::V2::BaseService
  def create_custom_pricing_unit(display_name:, lookup_key:)
    StripeV2Client.request(
      :post,
      '/v2/billing/custom_pricing_units',
      { display_name: display_name, lookup_key: lookup_key },
      { api_key: ENV.fetch('STRIPE_SECRET_KEY', nil), stripe_version: '2025-08-27.preview' }
    )
  end

  def create_meter(display_name:, event_name:)
    params = {
      'display_name' => display_name,
      'event_name' => event_name,
      'default_aggregation[formula]' => 'sum',
      'customer_mapping[type]' => 'by_id',
      'customer_mapping[event_payload_key]' => 'stripe_customer_id',
      'value_settings[event_payload_key]' => 'value'
    }
    StripeV2Client.request(
      :post,
      '/v1/billing/meters',
      params,
      { api_key: ENV.fetch('STRIPE_SECRET_KEY', nil), stripe_version: '2025-08-27.preview' }
    )
  end

  def create_pricing_plan(display_name:, lookup_key:, currency: 'usd', tax_behavior: 'exclusive')
    StripeV2Client.request(
      :post,
      '/v2/billing/pricing_plans',
      { display_name: display_name, currency: currency, tax_behavior: tax_behavior, lookup_key: lookup_key },
      { api_key: ENV.fetch('STRIPE_SECRET_KEY', nil), stripe_version: '2025-08-27.preview' }
    )
  end

  def create_complete_pricing_plan(config)
    # Use shared CPU and meter if available, otherwise create new ones
    cpu = get_or_create_cpu(config)
    meter = get_or_create_meter(config)

    plan = create_pricing_plan(display_name: config[:plan_display_name], lookup_key: config[:plan_lookup_key])

    builder = component_builder
    builder.add_license_fee_component(plan, config) if config[:license_fee_amount].to_i.positive?
    builder.add_service_action_component(plan, config, cpu) if config[:monthly_credit_amount].to_i.positive?
    builder.add_rate_card_component(plan, config, meter, cpu)

    # Make the latest version live
    make_plan_version_live(plan.id)

    build_plan_result(plan, cpu, meter)
  end

  def get_or_create_cpu(config)
    shared_cpu_id = InstallationConfig.find_by(name: 'STRIPE_CUSTOM_PRICING_UNIT_ID')&.value

    if shared_cpu_id
      # Return existing CPU as OpenStruct to match create response
      OpenStruct.new(id: shared_cpu_id)
    else
      # Create new CPU if not using shared
      cpu = create_custom_pricing_unit(
        display_name: config[:cpu_display_name],
        lookup_key: config[:cpu_lookup_key]
      )

      installation_config = InstallationConfig.find_or_initialize_by(name: 'STRIPE_CUSTOM_PRICING_UNIT_ID')
      installation_config.value = cpu.id
      installation_config.save!

      cpu
    end
  end

  def get_or_create_meter(config)
    # Check for shared meter first
    shared_meter_id = InstallationConfig.find_by(name: 'STRIPE_METER_ID')&.value ||
                      ENV.fetch('STRIPE_METER_ID', nil)

    if shared_meter_id
      # Return existing meter as OpenStruct to match create response
      OpenStruct.new(id: shared_meter_id)
    else
      # Create new meter if not using shared
      meter = create_meter(
        display_name: config[:meter_display_name],
        event_name: config[:meter_event_name]
      )

      installation_config = InstallationConfig.find_or_initialize_by(name: 'STRIPE_METER_ID')
      installation_config.value = meter.id
      installation_config.save!

      meter
    end
  end

  private

  def component_builder
    @component_builder ||= Enterprise::Billing::V2::PricingPlanComponentBuilder.new(account: account)
  end

  def make_plan_version_live(plan_id)
    StripeV2Client.request(
      :post,
      "/v2/billing/pricing_plans/#{plan_id}",
      { live_version: 'latest' },
      { api_key: ENV.fetch('STRIPE_SECRET_KEY', nil), stripe_version: '2025-08-27.preview' }
    )
  end

  def build_plan_result(plan, cpu, meter)
    {
      success: true,
      pricing_plan: plan,
      custom_pricing_unit: cpu,
      meter: meter
    }
  end
end
