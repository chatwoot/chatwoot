require 'rails_helper'

describe Enterprise::Billing::V2::SubscriptionProvisioningService do
  let(:account) { create(:account) }
  let(:service) { described_class.new(account: account) }
  let(:subscription_id) { 'bpps_subscription_123' }
  let(:pricing_plan_id) { 'bpp_business_plan_123' }

  before do
    account.update!(custom_attributes: { 'stripe_billing_version' => 2, 'pending_subscription_quantity' => 5 })
    create(:installation_config, name: 'STRIPE_BUSINESS_PLAN_ID', value: pricing_plan_id)
  end

  describe '#provision' do
    let(:subscription_response) do
      OpenStruct.new(
        id: subscription_id,
        pricing_plan: pricing_plan_id,
        component_values: [
          { 'type' => 'license_fee', 'quantity' => 5 }
        ]
      )
    end

    before do
      allow(StripeV2Client).to receive(:request).and_return(subscription_response)
    end

    it 'retrieves subscription details from Stripe' do
      service.provision(subscription_id: subscription_id)

      expect(StripeV2Client).to have_received(:request).with(
        :get,
        "/v2/billing/pricing_plan_subscriptions/#{subscription_id}",
        {},
        hash_including(api_key: ENV.fetch('STRIPE_SECRET_KEY', nil), stripe_version: '2025-08-27.preview')
      )
    end

    it 'updates account custom attributes with subscription details' do
      result = service.provision(subscription_id: subscription_id)

      expect(result[:success]).to be(true)
      expect(account.custom_attributes['stripe_billing_version']).to eq(2)
      expect(account.custom_attributes['stripe_subscription_id']).to eq(subscription_id)
      expect(account.custom_attributes['stripe_pricing_plan_id']).to eq(pricing_plan_id)
      expect(account.custom_attributes['subscribed_quantity']).to eq(5)
      expect(account.custom_attributes['subscription_status']).to eq('active')
      expect(account.custom_attributes['plan_name']).to eq('Chatwoot Business')
    end

    it 'syncs monthly credits based on plan' do
      credit_service = instance_double(Enterprise::Billing::V2::CreditManagementService)
      allow(Enterprise::Billing::V2::CreditManagementService)
        .to receive(:new)
        .with(account: account)
        .and_return(credit_service)
      allow(credit_service).to receive(:sync_monthly_credits)

      service.provision(subscription_id: subscription_id)

      expect(credit_service).to have_received(:sync_monthly_credits).with(50_000)
    end

    it 'enables plan-specific features' do
      service.provision(subscription_id: subscription_id)

      expected_features = %w[
        inbound_emails
        help_center
        campaigns
        team_management
        channel_twitter
        channel_facebook
        channel_email
        channel_instagram
        captain_integration
        advanced_search_indexing
        sla
        custom_roles
      ]
      enabled_feature_names = account.enabled_features.map(&:first)
      expect(enabled_feature_names).to match_array(expected_features)
    end

    it 'returns success response with subscription details' do
      result = service.provision(subscription_id: subscription_id)

      expect(result[:success]).to be(true)
      expect(result[:subscription_id]).to eq(subscription_id)
      expect(result[:pricing_plan_id]).to eq(pricing_plan_id)
      expect(result[:quantity]).to eq(5)
      expect(result[:message]).to eq('Subscription provisioned successfully')
    end

    context 'when pricing plan has no license fee component' do
      let(:subscription_response) do
        OpenStruct.new(
          id: subscription_id,
          pricing_plan: pricing_plan_id,
          component_values: []
        )
      end

      before do
        # Clear pending_subscription_quantity to test default behavior
        account.update!(custom_attributes: account.custom_attributes.except('pending_subscription_quantity'))
      end

      it 'defaults quantity to 1' do
        result = service.provision(subscription_id: subscription_id)

        expect(result[:quantity]).to eq(1)
        expect(account.custom_attributes['subscribed_quantity']).to eq(1)
      end
    end

    context 'when Stripe API returns an error' do
      before do
        allow(StripeV2Client).to receive(:request).and_raise(Stripe::StripeError.new('API error'))
      end

      it 'returns error response' do
        result = service.provision(subscription_id: subscription_id)

        expect(result[:success]).to be(false)
        expect(result[:message]).to include('Stripe error')
      end
    end

    context 'with Startup plan' do
      let(:startup_plan_id) { 'bpp_startup_plan_123' }
      let(:subscription_response) do
        OpenStruct.new(
          id: subscription_id,
          pricing_plan: startup_plan_id,
          component_values: [{ 'type' => 'license_fee', 'quantity' => 3 }]
        )
      end

      before do
        create(:installation_config, name: 'STRIPE_STARTUP_PLAN_ID', value: startup_plan_id)
      end

      it 'enables only Startup features' do
        service.provision(subscription_id: subscription_id)

        expected_features = %w[
          inbound_emails
          help_center
          campaigns
          team_management
          channel_twitter
          channel_facebook
          channel_email
          channel_instagram
          captain_integration
          advanced_search_indexing
        ]
        enabled_feature_names = account.enabled_features.map(&:first)
        expect(enabled_feature_names).to match_array(expected_features)
      end
    end

    context 'with Enterprise plan' do
      let(:enterprise_plan_id) { 'bpp_enterprise_plan_123' }
      let(:subscription_response) do
        OpenStruct.new(
          id: subscription_id,
          pricing_plan: enterprise_plan_id,
          component_values: [{ 'type' => 'license_fee', 'quantity' => 10 }]
        )
      end

      before do
        create(:installation_config, name: 'STRIPE_ENTERPRISE_PLAN_ID', value: enterprise_plan_id)
      end

      it 'enables all features including Enterprise-specific ones' do
        service.provision(subscription_id: subscription_id)

        expected_features = %w[
          inbound_emails
          help_center
          campaigns
          team_management
          channel_twitter
          channel_facebook
          channel_email
          channel_instagram
          captain_integration
          advanced_search_indexing
          sla
          custom_roles
          audit_logs
          disable_branding
          saml
        ]
        enabled_feature_names = account.enabled_features.map(&:first)
        expect(enabled_feature_names).to match_array(expected_features)
      end
    end
  end
end
