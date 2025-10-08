require 'rails_helper'

RSpec.describe Enterprise::Billing::V2::PricingPlanService do
  let(:account) { create(:account) }
  let(:service) { described_class.new(account: account) }

  before do
    allow(ENV).to receive(:fetch).with('STRIPE_SECRET_KEY', nil).and_return('sk_test_123')
  end

  describe '#create_custom_pricing_unit' do
    it 'creates a custom pricing unit' do
      cpu_double = instance_double(Stripe::V2::Billing::CustomPricingUnit, id: 'cpu_123')
      allow(Stripe::V2::Billing::CustomPricingUnit).to receive(:create).and_return(cpu_double)

      result = service.create_custom_pricing_unit(display_name: 'Credits', lookup_key: 'credits_001')

      expect(result.id).to eq('cpu_123')
    end
  end

  describe '#create_meter' do
    it 'creates a billing meter' do
      meter_double = instance_double(Stripe::Billing::Meter, id: 'meter_123')
      allow(Stripe::Billing::Meter).to receive(:create).and_return(meter_double)

      result = service.create_meter(display_name: 'Prompts', event_name: 'prompts_001')

      expect(result.id).to eq('meter_123')
    end
  end

  describe '#create_pricing_plan' do
    it 'creates a pricing plan' do
      plan_double = instance_double(Stripe::V2::Billing::PricingPlan, id: 'plan_123')
      allow(Stripe::V2::Billing::PricingPlan).to receive(:create).and_return(plan_double)

      result = service.create_pricing_plan(display_name: 'Business Plan')

      expect(result.id).to eq('plan_123')
    end
  end

  describe '#create_service_action' do
    it 'creates a service action for monthly credit grants' do
      action_double = instance_double(Stripe::V2::Billing::ServiceAction, id: 'sa_123')
      allow(Stripe::V2::Billing::ServiceAction).to receive(:create).and_return(action_double)

      result = service.create_service_action(
        lookup_key: 'monthly_credits_001',
        cpu_id: 'cpu_123',
        credit_amount: 2000
      )

      expect(result.id).to eq('sa_123')
    end
  end

  describe '#create_complete_pricing_plan' do
    let(:config) do
      {
        cpu_display_name: 'Captain Credits',
        cpu_lookup_key: 'captain_credits_001',
        meter_display_name: 'Captain Prompts',
        meter_event_name: 'captain_prompts_001',
        plan_display_name: 'Business Plan - 2000 Credits',
        include_license_fee: true,
        licensed_item_display_name: 'Business Seat',
        licensed_item_lookup_key: 'business_seat_001',
        licensed_item_unit_label: 'per agent',
        license_fee_display_name: 'Business Monthly Fee',
        license_fee_amount: '3900',
        service_action_lookup_key: 'monthly_credits_001',
        monthly_credit_amount: 2000,
        rate_card_display_name: 'Usage Rates',
        metered_item_display_name: 'Captain Prompt',
        metered_item_lookup_key: 'captain_prompt_001',
        rate_value: 1
      }
    end

    it 'creates a complete pricing plan with all components' do
      cpu = instance_double(Stripe::V2::Billing::CustomPricingUnit, id: 'cpu_123')
      meter = instance_double(Stripe::Billing::Meter, id: 'meter_123')
      plan = instance_double(Stripe::V2::Billing::PricingPlan, id: 'plan_123')
      licensed_item = instance_double(Stripe::V2::Billing::LicensedItem, id: 'li_123')
      license_fee = instance_double(Stripe::V2::Billing::LicenseFee, id: 'lf_123', latest_version: 'v1')
      service_action = instance_double(Stripe::V2::Billing::ServiceAction, id: 'sa_123')
      rate_card = instance_double(Stripe::V2::Billing::RateCard, id: 'rc_123', latest_version: 'v1')
      metered_item = instance_double(Stripe::V2::Billing::MeteredItem, id: 'mi_123')

      allow(service).to receive(:create_custom_pricing_unit).and_return(cpu)
      allow(service).to receive(:create_meter).and_return(meter)
      allow(service).to receive(:create_pricing_plan).and_return(plan)
      allow(service).to receive(:create_licensed_item).and_return(licensed_item)
      allow(service).to receive(:create_license_fee).and_return(license_fee)
      allow(service).to receive(:create_service_action).and_return(service_action)
      allow(service).to receive(:create_rate_card).and_return(rate_card)
      allow(service).to receive(:create_metered_item).and_return(metered_item)
      allow(service).to receive(:add_rate_to_rate_card).and_return(true)
      allow(service).to receive(:add_component_to_plan).and_return(true)

      result = service.create_complete_pricing_plan(config)

      expect(result[:success]).to be true
      expect(result[:pricing_plan]).to eq(plan)
      expect(result[:custom_pricing_unit]).to eq(cpu)
      expect(result[:meter]).to eq(meter)
      expect(result[:service_action]).to eq(service_action)
    end
  end
end
