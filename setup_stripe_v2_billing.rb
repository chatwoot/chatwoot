#!/usr/bin/env ruby

require 'stripe'
require 'httparty'
require 'optparse'
require 'json'

# Provision core V2 Billing objects using Stripe Ruby client.

class StripeV2Provisioner
  def initialize(api_key:, api_version: ENV.fetch('STRIPE_API_VERSION', '2024-09-30.acacia'))
    Stripe.api_key = api_key
    Stripe.api_version = api_version
    @client = Stripe::StripeClient.new(api_key: api_key)
    @api_key = api_key
    @api_version = api_version
  end

  def run!
    meter = ensure_meter
    results = { meter: meter }
    v2 = provision_v2_resources(meter)
    results.merge!(v2) if v2
    print_summary(results)
  end

  def ensure_meter
    find_or_create_meter(env_suffix('captain_prompts'), 'Captain Prompts')
  end

  def provision_v2_resources(meter)
    resources = create_v2_core(meter)
    attach_and_publish(resources)
    resources
  rescue StandardError => e
    warn "[WARN] V2 provisioning skipped due to: #{e.message}"
    nil
  end

  def create_v2_core(meter)
    cpu  = create_custom_pricing_unit
    plan = create_pricing_plan
    item = create_licensed_item
    fee  = create_license_fee(item['id'])
    svc  = create_service_action(cpu['id'])
    mi   = create_metered_item(meter['id'])
    rc   = create_rate_card
    add_rate(rc['id'], mi['id'], cpu['id'])
    { cpu: cpu, plan: plan, licensed_item: item, license_fee: fee, service_action: svc, metered_item: mi, rate_card: rc }
  end

  def attach_and_publish(res)
    attach_components(res[:plan]['id'], res[:license_fee], res[:service_action], res[:rate_card])
    publish_plan(res[:plan]['id'])
  end

  def create_custom_pricing_unit
    post('/v2/billing/custom_pricing_units', display_name: 'Captain Credits', lookup_key: env_suffix('captain_credits'))
  end

  def find_or_create_meter(event_name, display_name)
    list = get('/v1/billing/meters', limit: 100)
    arr = list.is_a?(Hash) ? (list['data'] || []) : Array(list)
    existing = arr.find { |m| (m['event_name'] || m[:event_name]) == event_name }
    return existing if existing

    post('/v1/billing/meters',
         display_name: display_name,
         event_name: event_name,
         default_aggregation: { formula: 'sum' },
         customer_mapping: { type: 'by_id', event_payload_key: 'stripe_customer_id' },
         value_settings: { event_payload_key: 'value' })
  end

  def create_pricing_plan
    post('/v2/billing/pricing_plans', display_name: env_suffix('Chatwoot Business Plan'), currency: 'usd', tax_behavior: 'exclusive')
  end

  def create_licensed_item
    post('/v2/billing/licensed_items', display_name: 'Business Agent Seat', lookup_key: env_suffix('business_agent'), unit_label: 'per agent')
  end

  def create_license_fee(licensed_item_id)
    post('/v2/billing/license_fees', display_name: 'Business Monthly Fee', currency: 'usd', service_interval: 'month', service_interval_count: 1,
                                     tax_behavior: 'exclusive', unit_amount: '3900', licensed_item: licensed_item_id)
  end

  def create_service_action(cpu_id)
    post(
      '/v2/billing/service_actions',
      lookup_key: env_suffix('business_monthly_credits'),
      service_interval: 'month',
      service_interval_count: 1,
      type: 'credit_grant',
      credit_grant: {
        name: 'Business Monthly Credits',
        amount: {
          type: 'custom_pricing_unit',
          custom_pricing_unit: { id: cpu_id, value: '2000' }
        },
        expiry_config: { type: 'end_of_service_period' },
        applicability_config: { scope: { price_type: 'metered' } }
      }
    )
  end

  def create_metered_item(meter_id)
    post('/v2/billing/metered_items', display_name: 'Captain Prompt', lookup_key: env_suffix('captain_prompt'), meter: meter_id)
  end

  def create_rate_card
    post(
      '/v2/billing/rate_cards',
      display_name: env_suffix('Chatwoot Usage Rates'),
      currency: 'usd',
      service_interval: 'month',
      service_interval_count: 1,
      tax_behavior: 'exclusive'
    )
  end

  def add_rate(rate_card_id, metered_item_id, cpu_id)
    post("/v2/billing/rate_cards/#{rate_card_id}/rates", metered_item: metered_item_id, custom_pricing_unit_amount: { id: cpu_id, value: '1' })
  end

  def attach_components(plan_id, license_fee, service_action, rate_card)
    post(
      "/v2/billing/pricing_plans/#{plan_id}/components",
      type: 'license_fee',
      license_fee: { id: license_fee['id'], version: license_fee['latest_version'] }
    )
    post(
      "/v2/billing/pricing_plans/#{plan_id}/components",
      type: 'credit_grant',
      service_action: { id: service_action['id'] }
    )
    post(
      "/v2/billing/pricing_plans/#{plan_id}/components",
      type: 'rate_card',
      rate_card: { id: rate_card['id'], version: rate_card['latest_version'] }
    )
  end

  def publish_plan(plan_id)
    post("/v2/billing/pricing_plans/#{plan_id}", live_version: 'latest')
  end

  def print_summary(results)
    puts "\n--- Stripe V2 IDs ---"
    puts JSON.pretty_generate(StripeV2Printer.build_summary(results))
    puts "\nEnvironment variables to set:"
    puts 'STRIPE_V2_ENABLED=true'
    StripeV2Printer.print_env_vars(results, env_suffix('captain_prompts'))
    puts "STRIPE_API_VERSION=#{Stripe.api_version}"
  end

  private

  def env_suffix(base)
    env = ENV.fetch('RAILS_ENV', 'development')
    "#{base}_#{env}"
  end

  def post(path, **params)
    if path.start_with?('/v2')
      http_post_v2(path, params)
    else
      # Use Stripe gem for v1 endpoints
      @client.execute_request(:post, path, params: params)
    end
  end

  def get(path, **params)
    url = "https://api.stripe.com#{path}"
    headers = { 'Authorization' => "Bearer #{@api_key}" }
    response = HTTParty.get(url, headers: headers, query: params)
    raise(StandardError, response.parsed_response) unless response.success?

    response.parsed_response
  end

  def http_post_v2(path, params)
    url = "https://api.stripe.com#{path}"
    headers = {
      'Authorization' => "Bearer #{@api_key}",
      'Stripe-Version' => @api_version,
      'Stripe-Api-Version' => @api_version,
      'Content-Type' => 'application/json'
    }
    response = HTTParty.post(url, headers: headers, body: JSON.generate(params))
    raise(StandardError, response.parsed_response) unless response.success?

    response.parsed_response
  end
end

module StripeV2Printer
  module_function

  def build_summary(results)
    mapping = {
      meter: :meter_id,
      cpu: :cpu_id,
      plan: :plan_id,
      licensed_item: :licensed_item_id,
      license_fee: :license_fee_id,
      service_action: :service_action_id,
      metered_item: :metered_item_id,
      rate_card: :rate_card_id
    }
    mapping.each_with_object({}) do |(key, out_key), acc|
      obj = results[key]
      id = obj && obj['id']
      acc[out_key] = id if id
    end
  end

  def print_env_vars(results, event_name)
    meter_id = results[:meter] && results[:meter]['id']
    plan_id  = results[:plan] && results[:plan]['id']
    if meter_id
      puts "STRIPE_V2_METER_ID=#{meter_id}"
      puts "STRIPE_V2_METER_EVENT_NAME=#{event_name}"
    end
    puts "STRIPE_V2_BUSINESS_PLAN_ID=#{plan_id}" if plan_id
  end
end

if __FILE__ == $PROGRAM_NAME
  options = {}
  OptionParser.new do |opts|
    opts.banner = 'Usage: ruby setup_stripe_v2_billing.rb --key sk_test_xxx [--version 2025-08-27.preview]'
    opts.on('-k', '--key KEY', 'Stripe secret key') { |v| options[:key] = v }
    opts.on('-v', '--version VERSION', 'Stripe API version') { |v| options[:version] = v }
  end.parse!

  key = options[:key] || ENV.fetch('STRIPE_SECRET_KEY', nil)
  abort 'Missing STRIPE_SECRET_KEY' if key.to_s.strip.empty?

  StripeV2Provisioner.new(api_key: key, api_version: options[:version]).run!
end
