require 'rails_helper'

RSpec.describe Enterprise::Billing::V2::PricingPlanService do
  let(:account) { create(:account) }
  let(:service) { described_class.new(account: account) }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('STRIPE_SECRET_KEY', nil).and_return('sk_test_123')
  end

  describe '#create_custom_pricing_unit' do
    it 'creates a custom pricing unit' do
      cpu_response = OpenStruct.new(id: 'cpu_123')
      allow(StripeV2Client).to receive(:request).and_return(cpu_response)

      result = service.create_custom_pricing_unit(display_name: 'Credits', lookup_key: 'credits_001')

      expect(result.id).to eq('cpu_123')
      expect(StripeV2Client).to have_received(:request).with(
        :post,
        '/v2/billing/custom_pricing_units',
        { display_name: 'Credits', lookup_key: 'credits_001' },
        { api_key: 'sk_test_123', stripe_version: '2025-08-27.preview' }
      )
    end
  end

  describe '#create_meter' do
    it 'creates a billing meter' do
      meter_response = OpenStruct.new(id: 'meter_123')
      allow(StripeV2Client).to receive(:request).and_return(meter_response)

      result = service.create_meter(display_name: 'Prompts', event_name: 'prompts_001')

      expect(result.id).to eq('meter_123')
      expect(StripeV2Client).to have_received(:request).with(
        :post,
        '/v1/billing/meters',
        kind_of(Hash),
        { api_key: 'sk_test_123', stripe_version: '2025-08-27.preview' }
      )
    end
  end

  describe '#create_pricing_plan' do
    it 'creates a pricing plan' do
      plan_response = OpenStruct.new(id: 'plan_123')
      allow(StripeV2Client).to receive(:request).and_return(plan_response)

      result = service.create_pricing_plan(display_name: 'Business Plan', lookup_key: 'business_plan')

      expect(result.id).to eq('plan_123')
      expect(StripeV2Client).to have_received(:request).with(
        :post,
        '/v2/billing/pricing_plans',
        { display_name: 'Business Plan', currency: 'usd', tax_behavior: 'exclusive', lookup_key: 'business_plan' },
        { api_key: 'sk_test_123', stripe_version: '2025-08-27.preview' }
      )
    end
  end

  describe '#create_complete_pricing_plan' do
    # Clean up any existing InstallationConfig entries before each test
    before do
      InstallationConfig.where(name: %w[STRIPE_CUSTOM_PRICING_UNIT_ID STRIPE_METER_ID]).destroy_all
      # Also ensure ENV doesn't have STRIPE_METER_ID
      allow(ENV).to receive(:fetch).with('STRIPE_METER_ID', nil).and_return(nil)
    end

    let(:cpu) { OpenStruct.new(id: 'cpu_123') }
    let(:meter) { OpenStruct.new(id: 'meter_123') }
    let(:plan) { OpenStruct.new(id: 'plan_123') }
    let(:service_action) { OpenStruct.new(id: 'sa_123') }
    let(:rate_card) { OpenStruct.new(id: 'rc_123', latest_version: 'v1') }
    let(:live_plan) { OpenStruct.new(id: 'plan_123', live_version: 'latest') }

    let(:config) do
      {
        # Shared resources
        cpu_display_name: 'Credits',
        cpu_lookup_key: 'cpu_001',
        meter_display_name: 'Prompts',
        meter_event_name: 'prompts_001',

        # Plan details
        plan_display_name: 'Business Plan',
        plan_lookup_key: 'business_plan',

        # Component-specific lookup keys (each must be unique)
        lookup_key: 'chatwoot_business_agents', # Used for license fee
        service_action_lookup_key: 'chatwoot_business_credits',
        metered_item_lookup_key: 'chatwoot_business_usage',

        # License fee
        licensed_item_display_name: 'Seat',
        licensed_item_unit_label: 'per agent',
        license_fee_display_name: 'Fee',
        license_fee_amount: 3900,

        # Service action (monthly credits)
        monthly_credit_amount: 2000,

        # Rate card (overage)
        rate_card_display_name: 'Rates',
        metered_item_display_name: 'Prompt',
        rate_value: 1
      }
    end

    def stub_stripe_client
      allow(StripeV2Client).to receive(:request) do |_method, path, *_args|
        case path
        when '/v2/billing/custom_pricing_units' then cpu
        when '/v1/billing/meters' then meter
        when '/v2/billing/pricing_plans' then plan
        when '/v2/billing/pricing_plans/plan_123' then live_plan
        end
      end
    end

    def stub_component_builder
      component_builder = instance_double(Enterprise::Billing::V2::PricingPlanComponentBuilder)
      allow(component_builder).to receive(:add_license_fee_component).and_return(true)
      allow(component_builder).to receive(:add_service_action_component).and_return(service_action)
      allow(component_builder).to receive(:add_rate_card_component).and_return(rate_card)
      allow(service).to receive(:component_builder).and_return(component_builder)
    end

    it 'creates a complete pricing plan with all components' do
      stub_stripe_client
      stub_component_builder

      result = service.create_complete_pricing_plan(config)

      expect(result[:success]).to be true
      expect(result[:pricing_plan]).to eq(plan)
      expect(result[:custom_pricing_unit]).to eq(cpu)
      expect(result[:meter]).to eq(meter)
      expect(result[:service_action]).to eq(service_action)
      expect(InstallationConfig.find_by(name: 'STRIPE_CUSTOM_PRICING_UNIT_ID')&.value).to eq('cpu_123')
      expect(InstallationConfig.find_by(name: 'STRIPE_METER_ID')&.value).to eq('meter_123')
    end
  end
end
