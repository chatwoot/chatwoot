require 'rails_helper'
# rubocop:disable RSpec/VerifiedDoubles

describe Enterprise::Billing::V2::WebhookHandlerService do
  let(:account) { create(:account) }
  let(:service) { described_class.new(account: account) }
  let(:credit_service) { instance_double(Enterprise::Billing::V2::CreditManagementService) }

  before do
    account.update!(custom_attributes: { 'stripe_billing_version' => 2, 'pending_subscription_quantity' => 5 })
    allow(Enterprise::Billing::V2::CreditManagementService).to receive(:new).with(account: account).and_return(credit_service)
  end

  describe '#process' do
    context 'when handling subscription servicing activated' do
      let(:subscription_response) do
        OpenStruct.new(
          id: 'bpps_subscription_123',
          pricing_plan: 'bpp_business_plan_123',
          component_values: [{ 'type' => 'license_fee', 'quantity' => 5 }]
        )
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
        allow(StripeV2Client).to receive(:request).and_return(subscription_response)
        allow(credit_service).to receive(:sync_monthly_credits)
      end

      it 'returns success with subscription details' do
        result = service.process(event)

        expect(result[:success]).to be(true), "Expected success but got: #{result.inspect}"
        expect(result[:subscription_id]).to eq('bpps_subscription_123')
        expect(result[:pricing_plan_id]).to eq('bpp_business_plan_123')
        expect(result[:quantity]).to eq(5)
      end

      it 'updates account custom attributes' do
        service.process(event)

        expect(account.custom_attributes['stripe_subscription_id']).to eq('bpps_subscription_123')
        expect(account.custom_attributes['stripe_pricing_plan_id']).to eq('bpp_business_plan_123')
        expect(account.custom_attributes['subscribed_quantity']).to eq(5)
        expect(account.custom_attributes['subscription_status']).to eq('active')
        expect(account.custom_attributes['plan_name']).to eq('Chatwoot Business')
      end

      it 'syncs monthly credits' do
        service.process(event)

        expect(credit_service).to have_received(:sync_monthly_credits).with(50_000)
      end

      it 'provisions features for the plan' do
        service.process(event)

        enabled_feature_names = account.enabled_features.map(&:first)
        expect(enabled_feature_names).to match_array(expected_features)
      end
    end

    context 'when handling unknown event' do
      it 'returns success' do
        related_object = OpenStruct.new(id: 'unknown_id')
        event = double('Stripe::Event', type: 'unknown.event', related_object: related_object)

        result = service.process(event)

        expect(result[:success]).to be(true)
      end
    end
  end
end
# rubocop:enable RSpec/VerifiedDoubles
