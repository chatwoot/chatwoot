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
      event_double = double
      allow(event_double).to receive(:blank?).and_return(false)
      allow(event_double).to receive(:type).and_return('v2.billing.pricing_plan_subscription.servicing_activated')
      allow(event_double).to receive(:related_object).and_return(OpenStruct.new(id: 'bpps_sub_123'))
      event_double
    end

    before do
      account # Ensure account is created
      create(:installation_config, name: 'STRIPE_BUSINESS_PLAN_ID', value: pricing_plan_id)

      # Mock the Stripe gem client methods
      stripe_client_double = double
      v2_double = double
      billing_double = double
      subscriptions_double = double
      cadences_double = double

      allow(service).to receive(:stripe_client).and_return(stripe_client_double)
      allow(stripe_client_double).to receive(:v2).and_return(v2_double)
      allow(v2_double).to receive(:billing).and_return(billing_double)
      allow(billing_double).to receive(:pricing_plan_subscriptions).and_return(subscriptions_double)
      allow(billing_double).to receive(:cadences).and_return(cadences_double)

      allow(subscriptions_double).to receive(:retrieve).with('bpps_sub_123').and_return(subscription_response)
      allow(cadences_double).to receive(:retrieve).with('cad_123').and_return(cadence_response)
    end

    it 'handles subscription activation' do
      # Mock the subscription provisioning service
      provisioning_service_double = instance_double(
        Enterprise::Billing::V2::SubscriptionProvisioningService,
        provision: { pricing_plan_id: pricing_plan_id, quantity: 1 }
      )
      allow(Enterprise::Billing::V2::SubscriptionProvisioningService).to receive(:new)
        .with(account: account)
        .and_return(provisioning_service_double)

      result = service.perform(event: event)

      expect(provisioning_service_double).to have_received(:provision).with(subscription_id: 'bpps_sub_123')
      expect(result[:pricing_plan_id]).to eq(pricing_plan_id)
    end
  end
end
