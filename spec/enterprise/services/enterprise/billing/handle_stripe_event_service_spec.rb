require 'rails_helper'

describe Enterprise::Billing::HandleStripeEventService do
  subject(:stripe_event_service) { described_class }

  let(:event) { double }
  let(:data) { double }
  let(:subscription) { double }
  let!(:account) { create(:account, custom_attributes: { stripe_customer_id: 'cus_123' }) }

  before do
    # Create cloud plans configuration
    create(:installation_config, {
             name: 'CHATWOOT_CLOUD_PLANS',
             value: [
               { 'name' => 'Hacker', 'product_id' => ['plan_id_hacker'], 'price_ids' => ['price_hacker'] },
               { 'name' => 'Startups', 'product_id' => ['plan_id_startups'], 'price_ids' => ['price_startups'] },
               { 'name' => 'Business', 'product_id' => ['plan_id_business'], 'price_ids' => ['price_business'] },
               { 'name' => 'Enterprise', 'product_id' => ['plan_id_enterprise'], 'price_ids' => ['price_enterprise'] }
             ]
           })
    # Setup common subscription mocks
    allow(event).to receive(:data).and_return(data)
    allow(data).to receive(:object).and_return(subscription)
    allow(subscription).to receive(:[]).with('quantity').and_return('10')
    allow(subscription).to receive(:[]).with('status').and_return('active')
    allow(subscription).to receive(:[]).with('current_period_end').and_return(1_686_567_520)
    allow(subscription).to receive(:customer).and_return('cus_123')
    allow(event).to receive(:type).and_return('customer.subscription.updated')
  end

  describe 'subscription update handling' do
    it 'updates account attributes and disables premium features for default plan' do
      # Setup for default (Hacker) plan
      allow(subscription).to receive(:[]).with('plan')
                                         .and_return({ 'id' => 'test', 'product' => 'plan_id_hacker', 'name' => 'Hacker' })

      stripe_event_service.new.perform(event: event)

      # Verify account attributes were updated
      expect(account.reload.custom_attributes).to include(
        'plan_name' => 'Hacker',
        'stripe_product_id' => 'plan_id_hacker',
        'subscription_status' => 'active'
      )

      # Verify premium features are disabled for default plan
      expect(account).not_to be_feature_enabled('channel_email')
      expect(account).not_to be_feature_enabled('help_center')
      expect(account).not_to be_feature_enabled('sla')
      expect(account).not_to be_feature_enabled('custom_roles')
      expect(account).not_to be_feature_enabled('audit_logs')
    end

    it 'resets captain usage on subscription update' do
      # Prime the account with some usage
      5.times { account.increment_response_usage }
      expect(account.custom_attributes['captain_responses_usage']).to eq(5)

      # Setup for any plan
      allow(subscription).to receive(:[]).with('plan')
                                         .and_return({ 'id' => 'test', 'product' => 'plan_id_startups', 'name' => 'Startups' })

      stripe_event_service.new.perform(event: event)

      # Verify usage was reset
      expect(account.reload.custom_attributes['captain_responses_usage']).to eq(0)
    end
  end

  describe 'subscription deletion handling' do
    it 'calls CreateStripeCustomerService on subscription deletion' do
      allow(event).to receive(:type).and_return('customer.subscription.deleted')

      # Create a double for the service
      customer_service = double
      allow(Enterprise::Billing::CreateStripeCustomerService).to receive(:new)
        .with(account: account).and_return(customer_service)
      allow(customer_service).to receive(:perform)

      stripe_event_service.new.perform(event: event)

      # Verify the service was called
      expect(Enterprise::Billing::CreateStripeCustomerService).to have_received(:new)
        .with(account: account)
      expect(customer_service).to have_received(:perform)
    end
  end

  describe 'plan-specific feature management' do
    context 'with default plan (Hacker)' do
      it 'disables all premium features' do
        allow(subscription).to receive(:[]).with('plan')
                                           .and_return({ 'id' => 'test', 'product' => 'plan_id_hacker', 'name' => 'Hacker' })

        # Enable features first
        described_class::STARTUP_PLAN_FEATURES.each do |feature|
          account.enable_features(feature)
        end
        account.enable_features(*described_class::BUSINESS_PLAN_FEATURES)
        account.enable_features(*described_class::ENTERPRISE_PLAN_FEATURES)
        account.save!

        account.reload
        expect(account).to be_feature_enabled(described_class::STARTUP_PLAN_FEATURES.first)

        stripe_event_service.new.perform(event: event)

        account.reload

        all_features = described_class::STARTUP_PLAN_FEATURES +
                       described_class::BUSINESS_PLAN_FEATURES +
                       described_class::ENTERPRISE_PLAN_FEATURES

        all_features.each do |feature|
          expect(account).not_to be_feature_enabled(feature)
        end
      end
    end

    context 'with Startups plan' do
      it 'enables common features but not premium features' do
        allow(subscription).to receive(:[]).with('plan')
                                           .and_return({ 'id' => 'test', 'product' => 'plan_id_startups', 'name' => 'Startups' })

        stripe_event_service.new.perform(event: event)

        # Verify basic (Startups) features are enabled
        account.reload
        described_class::STARTUP_PLAN_FEATURES.each do |feature|
          expect(account).to be_feature_enabled(feature)
        end

        # But business and enterprise features should be disabled
        described_class::BUSINESS_PLAN_FEATURES.each do |feature|
          expect(account).not_to be_feature_enabled(feature)
        end

        described_class::ENTERPRISE_PLAN_FEATURES.each do |feature|
          expect(account).not_to be_feature_enabled(feature)
        end
      end
    end

    context 'with Business plan' do
      it 'enables business-specific features' do
        allow(subscription).to receive(:[]).with('plan')
                                           .and_return({ 'id' => 'test', 'product' => 'plan_id_business', 'name' => 'Business' })

        stripe_event_service.new.perform(event: event)

        account.reload
        described_class::STARTUP_PLAN_FEATURES.each do |feature|
          expect(account).to be_feature_enabled(feature)
        end

        described_class::BUSINESS_PLAN_FEATURES.each do |feature|
          expect(account).to be_feature_enabled(feature)
        end

        described_class::ENTERPRISE_PLAN_FEATURES.each do |feature|
          expect(account).not_to be_feature_enabled(feature)
        end
      end
    end

    context 'with Enterprise plan' do
      it 'enables all business and enterprise features' do
        allow(subscription).to receive(:[]).with('plan')
                                           .and_return({ 'id' => 'test', 'product' => 'plan_id_enterprise', 'name' => 'Enterprise' })

        stripe_event_service.new.perform(event: event)

        account.reload
        described_class::STARTUP_PLAN_FEATURES.each do |feature|
          expect(account).to be_feature_enabled(feature)
        end

        described_class::BUSINESS_PLAN_FEATURES.each do |feature|
          expect(account).to be_feature_enabled(feature)
        end

        described_class::ENTERPRISE_PLAN_FEATURES.each do |feature|
          expect(account).to be_feature_enabled(feature)
        end
      end
    end
  end

  describe 'manually managed features' do
    let(:service) { stripe_event_service.new }
    let(:internal_attrs_service) { instance_double(Internal::Accounts::InternalAttributesService) }

    before do
      # Mock the internal attributes service
      allow(Internal::Accounts::InternalAttributesService).to receive(:new).with(account).and_return(internal_attrs_service)
    end

    context 'when downgrading with manually managed features' do
      it 'preserves manually managed features even when downgrading plans' do
        # Setup: account has Enterprise plan with manually managed features
        allow(subscription).to receive(:[]).with('plan')
                                           .and_return({ 'id' => 'test', 'product' => 'plan_id_enterprise', 'name' => 'Enterprise' })

        # Mock manually managed features
        allow(internal_attrs_service).to receive(:manually_managed_features).and_return(%w[audit_logs custom_roles])

        # First run to apply enterprise plan
        service.perform(event: event)
        account.reload

        # Verify features are enabled
        expect(account).to be_feature_enabled('audit_logs')
        expect(account).to be_feature_enabled('custom_roles')

        # Now downgrade to Hacker plan (which normally wouldn't have these features)
        allow(subscription).to receive(:[]).with('plan')
                                           .and_return({ 'id' => 'test', 'product' => 'plan_id_hacker', 'name' => 'Hacker' })

        service.perform(event: event)
        account.reload

        # Manually managed features should still be enabled despite plan downgrade
        expect(account).to be_feature_enabled('audit_logs')
        expect(account).to be_feature_enabled('custom_roles')

        # But other premium features should be disabled
        expect(account).not_to be_feature_enabled('channel_instagram')
        expect(account).not_to be_feature_enabled('help_center')
      end
    end
  end

  describe 'downgrade handling' do
    let(:service) { stripe_event_service.new }

    before do
      # Setup internal attributes service mock to return no manually managed features
      internal_attrs_service = instance_double(Internal::Accounts::InternalAttributesService)
      allow(Internal::Accounts::InternalAttributesService).to receive(:new).with(account).and_return(internal_attrs_service)
      allow(internal_attrs_service).to receive(:manually_managed_features).and_return([])
    end

    context 'when downgrading from Enterprise to Business plan' do
      before do
        # Start with Enterprise plan
        allow(subscription).to receive(:[]).with('plan')
                                           .and_return({ 'id' => 'test', 'product' => 'plan_id_enterprise', 'name' => 'Enterprise' })
        service.perform(event: event)
        account.reload
      end

      it 'retains business features but disables enterprise features' do
        # Verify enterprise features were enabled
        expect(account).to be_feature_enabled('audit_logs')

        # Downgrade to Business plan
        allow(subscription).to receive(:[]).with('plan')
                                           .and_return({ 'id' => 'test', 'product' => 'plan_id_business', 'name' => 'Business' })
        service.perform(event: event)

        account.reload
        expect(account).to be_feature_enabled('sla')
        expect(account).to be_feature_enabled('custom_roles')
        expect(account).not_to be_feature_enabled('audit_logs')
      end
    end

    context 'when downgrading from Business to Startups plan' do
      before do
        # Start with Business plan
        allow(subscription).to receive(:[]).with('plan')
                                           .and_return({ 'id' => 'test', 'product' => 'plan_id_business', 'name' => 'Business' })
        service.perform(event: event)
        account.reload
      end

      it 'retains startup features but disables business features' do
        # Verify business features were enabled
        expect(account).to be_feature_enabled('sla')

        # Downgrade to Startups plan
        allow(subscription).to receive(:[]).with('plan')
                                           .and_return({ 'id' => 'test', 'product' => 'plan_id_startups', 'name' => 'Startups' })
        service.perform(event: event)

        account.reload
        # Spot check one startup feature
        expect(account).to be_feature_enabled('channel_instagram')
        expect(account).not_to be_feature_enabled('sla')
        expect(account).not_to be_feature_enabled('custom_roles')
      end
    end

    context 'when downgrading from Startups to Hacker plan' do
      before do
        # Start with Startups plan
        allow(subscription).to receive(:[]).with('plan')
                                           .and_return({ 'id' => 'test', 'product' => 'plan_id_startups', 'name' => 'Startups' })
        service.perform(event: event)
        account.reload
      end

      it 'disables all premium features' do
        # Verify startup features were enabled
        expect(account).to be_feature_enabled('channel_instagram')

        # Downgrade to Hacker (default) plan
        allow(subscription).to receive(:[]).with('plan')
                                           .and_return({ 'id' => 'test', 'product' => 'plan_id_hacker', 'name' => 'Hacker' })
        service.perform(event: event)

        account.reload
        # Spot check that premium features are disabled
        expect(account).not_to be_feature_enabled('channel_instagram')
        expect(account).not_to be_feature_enabled('help_center')
      end
    end
  end

  describe 'credit grant handling' do
    let(:credit_service) { instance_double(Enterprise::Billing::V2::CreditManagementService) }

    before do
      allow(Enterprise::Billing::V2::CreditManagementService).to receive(:new)
        .with(account: account).and_return(credit_service)
    end

    context 'when handling monthly credit grant' do
      it 'adds credits from Stripe' do
        allow(credit_service).to receive(:add_response_topup_credits)

        # Webhook event object (minimal, just has ID)
        grant_event_object = OpenStruct.new(
          id: 'credgr_test_123',
          customer: 'cus_123'
        )
        allow(event).to receive(:type).and_return('billing.credit_grant.created')
        allow(data).to receive(:object).and_return(grant_event_object)

        # Full grant object from API (has complete amount structure)
        api_grant_response = OpenStruct.new(
          id: 'credgr_test_123',
          customer: 'cus_123',
          metadata: { 'credits' => '2000' },
          amount: OpenStruct.new(
            type: 'custom_pricing_unit',
            custom_pricing_unit: OpenStruct.new(value: 2000)
          ),
          expires_at: Time.current
        )
        allow(Stripe::Billing::CreditGrant).to receive(:retrieve)
          .with('credgr_test_123')
          .and_return(api_grant_response)

        stripe_event_service.new.perform(event: event)

        expect(credit_service).to have_received(:add_response_topup_credits).with(2000)
      end
    end

    context 'when handling topup credit grant' do
      it 'adds topup credits' do
        allow(credit_service).to receive(:add_response_topup_credits)

        # Webhook event object (minimal, just has ID)
        grant_event_object = OpenStruct.new(
          id: 'credgr_test_456',
          customer: 'cus_123'
        )
        allow(event).to receive(:type).and_return('billing.credit_grant.created')
        allow(data).to receive(:object).and_return(grant_event_object)

        # Full grant object from API (has complete amount structure)
        api_grant_response = OpenStruct.new(
          id: 'credgr_test_456',
          customer: 'cus_123',
          metadata: { 'credits' => '500' },
          amount: OpenStruct.new(
            type: 'custom_pricing_unit',
            custom_pricing_unit: OpenStruct.new(value: 500)
          ),
          expires_at: nil
        )
        allow(Stripe::Billing::CreditGrant).to receive(:retrieve)
          .with('credgr_test_456')
          .and_return(api_grant_response)

        stripe_event_service.new.perform(event: event)

        expect(credit_service).to have_received(:add_response_topup_credits).with(500)
      end
    end

    context 'when handling monetary type credit grant' do
      it 'adds credits from monetary grant' do
        allow(credit_service).to receive(:add_response_topup_credits)

        # Webhook event object (minimal, just has ID)
        grant_event_object = OpenStruct.new(
          id: 'credgr_test_monetary',
          customer: 'cus_123'
        )
        allow(event).to receive(:type).and_return('billing.credit_grant.created')
        allow(data).to receive(:object).and_return(grant_event_object)

        # Full grant object from API with monetary amount
        api_grant_response = OpenStruct.new(
          id: 'credgr_test_monetary',
          customer: 'cus_123',
          metadata: { 'credits' => '1000' },
          amount: OpenStruct.new(
            type: 'monetary',
            monetary: OpenStruct.new(
              currency: 'usd',
              value: 1000
            )
          ),
          expires_at: Time.current
        )
        allow(Stripe::Billing::CreditGrant).to receive(:retrieve)
          .with('credgr_test_monetary')
          .and_return(api_grant_response)

        stripe_event_service.new.perform(event: event)

        expect(credit_service).to have_received(:add_response_topup_credits).with(1000)
      end
    end

    context 'when handling credit grant with zero amount' do
      it 'does not call credit service' do
        # Webhook event object (minimal, just has ID)
        grant_event_object = OpenStruct.new(
          id: 'credgr_test_zero',
          customer: 'cus_123'
        )
        allow(event).to receive(:type).and_return('billing.credit_grant.created')
        allow(data).to receive(:object).and_return(grant_event_object)

        # Full grant object from API with zero amount
        api_grant_response = OpenStruct.new(
          id: 'credgr_test_zero',
          customer: 'cus_123',
          amount: OpenStruct.new(
            type: 'custom_pricing_unit',
            custom_pricing_unit: OpenStruct.new(value: 0)
          ),
          expires_at: Time.current
        )
        allow(Stripe::Billing::CreditGrant).to receive(:retrieve)
          .with('credgr_test_zero')
          .and_return(api_grant_response)

        stripe_event_service.new.perform(event: event)

        # Ensure we don't accidentally call these methods
        expect(Enterprise::Billing::V2::CreditManagementService).not_to have_received(:new)
      end
    end
  end
end
