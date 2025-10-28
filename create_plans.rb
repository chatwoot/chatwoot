# Validate environment before starting
if ENV['STRIPE_SECRET_KEY'].blank?
  puts '❌ ERROR: STRIPE_SECRET_KEY environment variable is not set'
  puts 'Please set it with: export STRIPE_SECRET_KEY=sk_test_...'
  exit 1
end

account = Account.first
if account.nil?
  puts '❌ ERROR: No accounts found in database'
  puts 'Please create an account first'
  exit 1
end

puts "Using account: #{account.name} (ID: #{account.id})"
puts "Stripe API: #{ENV.fetch('STRIPE_SECRET_KEY', nil)[0..10]}..."
puts ''

configs = [
  {
    cpu_display_name: 'Credits',
    cpu_lookup_key: 'cpu_credits',
    meter_display_name: 'Cw meter',
    meter_event_name: 'chatwoot.usage',
    plan_display_name: 'Chatwoot Hacker',
    plan_lookup_key: 'chatwoot_hacker_v2',
    lookup_key: 'chatwoot_hacker_license_fee_v2',
    service_action_lookup_key: 'chatwoot_hacker_plan_v2_credits',
    metered_item_lookup_key: 'chatwoot_hacker_plan_v2_usage',
    licensed_item_display_name: 'Seat',
    licensed_item_unit_label: 'per agent',
    license_fee_display_name: 'Fee',
    license_fee_amount: '0',
    monthly_credit_amount: 0,
    rate_card_display_name: 'Rates',
    metered_item_display_name: 'Prompt',
    rate_value: 1,
    config_key: 'STRIPE_HACKER_PLAN_ID'
  },
  {
    cpu_display_name: 'Credits',
    cpu_lookup_key: 'cpu_credits',
    meter_display_name: 'Cw meter',
    meter_event_name: 'chatwoot.usage',
    plan_display_name: 'Chatwoot Startup',
    plan_lookup_key: 'chatwoot_startup_v2',
    lookup_key: 'chatwoot_startup_license_fee_v2',
    service_action_lookup_key: 'chatwoot_startup_plan_v2_credits',
    metered_item_lookup_key: 'chatwoot_startup_plan_v2_usage',
    licensed_item_display_name: 'Seat',
    licensed_item_unit_label: 'per agent',
    license_fee_display_name: 'Fee',
    license_fee_amount: '1900',
    monthly_credit_amount: 10_000,
    rate_card_display_name: 'Rates',
    metered_item_display_name: 'Prompt',
    rate_value: 1,
    config_key: 'STRIPE_STARTUP_PLAN_ID'
  },
  {
    cpu_display_name: 'Credits',
    cpu_lookup_key: 'cpu_credits',
    meter_display_name: 'Cw meter',
    meter_event_name: 'chatwoot.usage',
    plan_display_name: 'Chatwoot Business',
    plan_lookup_key: 'chatwoot_business_v2',
    lookup_key: 'chatwoot_business_license_fee_v2',
    service_action_lookup_key: 'chatwoot_business_plan_v2_credits',
    metered_item_lookup_key: 'chatwoot_business_plan_v2_usage',
    licensed_item_display_name: 'Seat',
    licensed_item_unit_label: 'per agent',
    license_fee_display_name: 'Fee',
    license_fee_amount: '3900',
    monthly_credit_amount: 50_000,
    rate_card_display_name: 'Rates',
    metered_item_display_name: 'Prompt',
    rate_value: 1,
    config_key: 'STRIPE_BUSINESS_PLAN_ID'
  },
  {
    cpu_display_name: 'Credits',
    cpu_lookup_key: 'cpu_credits',
    meter_display_name: 'Cw meter',
    meter_event_name: 'chatwoot.usage',
    plan_display_name: 'Chatwoot Enterprise',
    plan_lookup_key: 'chatwoot_enterprise_plan_v2',
    lookup_key: 'chatwoot_enterprise_license_fee_v2',
    service_action_lookup_key: 'chatwoot_enterprise_plan_v2_credits',
    metered_item_lookup_key: 'chatwoot_enterprise_plan_v2_usage',
    licensed_item_display_name: 'Seat',
    licensed_item_unit_label: 'per agent',
    license_fee_display_name: 'Fee',
    license_fee_amount: '9900',
    monthly_credit_amount: 200_000,
    rate_card_display_name: 'Rates',
    metered_item_display_name: 'Prompt',
    rate_value: 1,
    config_key: 'STRIPE_ENTERPRISE_PLAN_ID'
  }
]

service = Enterprise::Billing::V2::PricingPlanService.new(account: account)

puts 'Creating pricing plans...'
puts ''

configs.each do |config|
  begin
    result = service.create_complete_pricing_plan(config)
  rescue StandardError => e
    result = { success: false, error: e.message }
    puts "Exception occurred: #{e.class}"
    puts "Message: #{e.message}"
    puts e.backtrace.first(5).join("\n")
  end

  if result[:success]
    # Save or update the pricing plan ID in InstallationConfig
    installation_config = InstallationConfig.find_or_initialize_by(name: config[:config_key])
    installation_config.value = result[:pricing_plan].id
    installation_config.save!

    puts "✓ Created #{config[:plan_display_name]}"
    puts "  Plan ID: #{result[:pricing_plan].id}"
    puts "  CPU ID: #{result[:custom_pricing_unit].id}"
    puts "  Meter ID: #{result[:meter].id}"
  else
    puts "✗ Failed to create #{config[:plan_display_name]}"
    puts "  Error: #{result[:error]}" if result[:error]
  end
  puts ''
end

puts 'Summary:'
puts '--------'
puts "CPU ID saved to: STRIPE_CUSTOM_PRICING_UNIT_ID = #{InstallationConfig.find_by(name: 'STRIPE_CUSTOM_PRICING_UNIT_ID')&.value}"
puts "Meter ID saved to: STRIPE_METER_ID = #{InstallationConfig.find_by(name: 'STRIPE_METER_ID')&.value}"
puts ''
configs.each do |config|
  plan_id = InstallationConfig.find_by(name: config[:config_key])&.value
  puts "#{config[:config_key]} = #{plan_id}"
end
