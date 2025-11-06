require 'rails_helper'

describe Enterprise::Billing::V2::WebhookHandlerService do
  let(:account) { create(:account, custom_attributes: { 'stripe_customer_id' => 'cus_123' }) }
  let(:service) { described_class.new }
  let(:pricing_plan_id) { 'bpp_plan_123' }

  describe '#perform' do
    let(:subscription_response) do
      OpenStruct.new(
        id: 'bpps_sub_123',
        billing_cadence: 'cad_123',
        pricing_plan: pricing_plan_id,
        servicing_status: 'active'
      )
    end
    let(:cadence_response) { OpenStruct.new(payer: OpenStruct.new(customer: 'cus_123')) }
    let(:event) do
      double('Stripe::Event', type: 'v2.billing.pricing_plan_subscription.servicing_activated', related_object: OpenStruct.new(id: 'bpps_sub_123')) # rubocop:disable RSpec/VerifiedDoubles
    end

    before do
      account # Ensure account is created
      create(:installation_config, name: 'STRIPE_BUSINESS_PLAN_ID', value: pricing_plan_id)
      # Mock the Stripe API calls
      allow(StripeV2Client).to receive(:request)
        .with(:get, '/v2/billing/pricing_plan_subscriptions/bpps_sub_123', anything, anything)
        .and_return(subscription_response)
      allow(StripeV2Client).to receive(:request)
        .with(:get, '/v2/billing/cadences/cad_123', anything, anything)
        .and_return(cadence_response)
    end

    it 'handles subscription activation' do
      result = service.perform(event: event)

      expect(result[:pricing_plan_id]).to eq(pricing_plan_id)
    end
  end
end
