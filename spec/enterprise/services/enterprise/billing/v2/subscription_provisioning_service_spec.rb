require 'rails_helper'

describe Enterprise::Billing::V2::SubscriptionProvisioningService do
  let(:account) { create(:account) }
  let(:service) { described_class.new(account: account) }
  let(:subscription_id) { 'bpps_subscription_123' }
  let(:pricing_plan_id) { 'bpp_business_plan_123' }

  before do
    account.update!(custom_attributes: { 'pending_subscription_quantity' => 5 })
    create(:installation_config, name: 'STRIPE_BUSINESS_PLAN_ID', value: pricing_plan_id)
  end

  describe '#provision' do
    let(:subscription_response) do
      # Mock Stripe::V2::Billing::PricingPlanSubscription object
      instance_double(
        Stripe::V2::Billing::PricingPlanSubscription,
        id: subscription_id,
        pricing_plan: pricing_plan_id,
        billing_cadence: 'bpc_cadence_123',
        servicing_status: 'active'
      )
    end

    before do
      # Mock the retrieve_pricing_plan_subscription method directly
      allow(service).to receive(:retrieve_pricing_plan_subscription).with(subscription_id).and_return(subscription_response)
    end

    it 'provisions subscription' do
      result = service.provision(subscription_id: subscription_id)

      expect(result[:pricing_plan_id]).to eq(pricing_plan_id)
      expect(result[:quantity]).to eq(5)
    end
  end

  describe '#refresh' do
    let(:subscription_response) do
      # Mock Stripe::V2::Billing::PricingPlanSubscription object
      instance_double(
        Stripe::V2::Billing::PricingPlanSubscription,
        id: 'bpps_sub_456',
        pricing_plan: pricing_plan_id,
        billing_cadence: 'bpc_cadence_123',
        servicing_status: 'active'
      )
    end

    before do
      account.update!(custom_attributes: { 'stripe_subscription_id' => 'bpps_sub_456' })

      # Mock the retrieve_pricing_plan_subscription method directly
      allow(service).to receive(:retrieve_pricing_plan_subscription).with('bpps_sub_456').and_return(subscription_response)
    end

    it 'refreshes subscription' do
      result = service.refresh

      expect(result[:pricing_plan_id]).to eq(pricing_plan_id)
    end
  end

  describe '#cancel subscription' do
    let(:subscription_response) do
      # Mock Stripe::V2::Billing::PricingPlanSubscription object with canceled status
      instance_double(
        Stripe::V2::Billing::PricingPlanSubscription,
        id: subscription_id,
        pricing_plan: pricing_plan_id,
        billing_cadence: 'bpc_cadence_123',
        servicing_status: 'canceled'
      )
    end

    let(:hacker_plan_id) { 'bpp_hacker_plan_123' }

    before do
      create(:installation_config, name: 'STRIPE_HACKER_PLAN_ID', value: hacker_plan_id)

      # Mock the retrieve_pricing_plan_subscription method directly
      allow(service).to receive(:retrieve_pricing_plan_subscription).with(subscription_id).and_return(subscription_response)
    end

    it 'cancels subscription and resets to hacker plan' do
      result = service.provision(subscription_id: subscription_id)

      expect(result[:pricing_plan_id]).to be_nil
      expect(result[:quantity]).to be_nil
      expect(account.custom_attributes['plan_name']).to eq('Hacker')
      expect(account.custom_attributes['stripe_subscription_id']).to be_nil
      expect(account.custom_attributes['subscription_status']).to eq('canceled')
    end
  end
end
