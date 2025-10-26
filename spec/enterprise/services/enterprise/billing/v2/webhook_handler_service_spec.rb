require 'rails_helper'
# rubocop:disable RSpec/VerifiedDoubles

describe Enterprise::Billing::V2::WebhookHandlerService do
  let(:account) do
    create(:account, custom_attributes: { 'stripe_customer_id' => 'cus_123', 'stripe_billing_version' => 2, 'pending_subscription_quantity' => 5 })
  end
  let(:service) { described_class.new }
  let(:credit_service) { instance_double(Enterprise::Billing::V2::CreditManagementService) }

  before do
    allow(Enterprise::Billing::V2::CreditManagementService).to receive(:new).with(account: account).and_return(credit_service)
    allow(ENV).to receive(:fetch).and_call_original
  end

  describe '#perform' do
    context 'when handling subscription servicing activated' do
      let(:subscription_response) do
        OpenStruct.new(
          id: 'bpps_subscription_123',
          pricing_plan: 'bpp_business_plan_123',
          billing_cadence: 'cadence_123',
          component_values: [{ 'type' => 'license_fee', 'quantity' => 5 }]
        )
      end

      let(:cadence_response) do
        OpenStruct.new(
          id: 'cadence_123',
          payer: OpenStruct.new(customer: 'cus_123')
        )
      end

      let(:provisioning_response) do
        {
          success: true,
          subscription_id: 'bpps_subscription_123',
          pricing_plan_id: 'bpp_business_plan_123',
          quantity: 5
        }
      end

      let(:event) do
        double(
          'Stripe::Event',
          type: 'v2.billing.pricing_plan_subscription.servicing_activated',
          related_object: OpenStruct.new(id: 'bpps_subscription_123')
        )
      end

      let(:expected_features) do
        %w[inbound_emails help_center campaigns team_management channel_twitter channel_facebook
           channel_email channel_instagram captain_integration advanced_search_indexing sla custom_roles]
      end

      before do
        create(:installation_config, name: 'STRIPE_BUSINESS_PLAN_ID', value: 'bpp_business_plan_123')

        # Mock account lookup via subscription and cadence
        allow(StripeV2Client).to receive(:request)
          .with(:get, '/v2/billing/pricing_plan_subscriptions/bpps_subscription_123', anything, anything)
          .and_return(subscription_response)
        allow(StripeV2Client).to receive(:request)
          .with(:get, '/v2/billing/cadences/cadence_123', anything, anything)
          .and_return(cadence_response)

        # Mock provisioning service
        provisioning_service = instance_double(Enterprise::Billing::V2::SubscriptionProvisioningService)
        allow(Enterprise::Billing::V2::SubscriptionProvisioningService).to receive(:new).with(account: account).and_return(provisioning_service)
        allow(provisioning_service).to receive(:provision).and_return(provisioning_response)

        allow(credit_service).to receive(:sync_monthly_credits)
      end

      it 'delegates to subscription provisioning service' do
        result = service.perform(event: event)

        expect(result[:success]).to be(true), "Expected success but got: #{result.inspect}"
        expect(Enterprise::Billing::V2::SubscriptionProvisioningService).to have_received(:new).with(account: account)
      end
    end

    context 'when handling unknown event' do
      it 'returns success' do
        related_object = OpenStruct.new(id: 'bpps_subscription_123')
        event = double('Stripe::Event', type: 'unknown.event', related_object: related_object)

        # Mock account lookup
        subscription_response = OpenStruct.new(billing_cadence: 'cadence_123')
        cadence_response = OpenStruct.new(payer: OpenStruct.new(customer: 'cus_123'))
        allow(StripeV2Client).to receive(:request)
          .with(:get, '/v2/billing/pricing_plan_subscriptions/bpps_subscription_123', anything, anything)
          .and_return(subscription_response)
        allow(StripeV2Client).to receive(:request)
          .with(:get, '/v2/billing/cadences/cadence_123', anything, anything)
          .and_return(cadence_response)

        result = service.perform(event: event)

        expect(result[:success]).to be(true)
      end
    end
  end
end
# rubocop:enable RSpec/VerifiedDoubles
