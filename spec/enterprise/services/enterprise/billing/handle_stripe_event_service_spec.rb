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
    context 'for cloud installations (with cloud plans config)' do
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
        expect(account).not_to be_feature_enabled('sla')
        expect(account).not_to be_feature_enabled('custom_roles')
        expect(account).not_to be_feature_enabled('audit_logs')
        expect(account).not_to be_feature_enabled('disable_branding')
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

    context 'for self-hosted installations (without cloud plans config)' do
      before do
        # Remove cloud plans config to simulate self-hosted
        InstallationConfig.find_by(name: 'CHATWOOT_CLOUD_PLANS')&.destroy
      end

      it 'processes subscription updates using billing_plans.yml mapping' do
        # Mock the subscription to have metadata or product that maps to a plan
        allow(subscription).to receive(:[]).with('plan')
                                           .and_return({ 'id' => 'price_starter', 'product' => 'prod_starter', 'name' => 'Starter' })
        allow(subscription).to receive(:dig).with('metadata', 'plan_name').and_return('starter')

        # Mock the service to return plan features
        allow_any_instance_of(described_class).to receive(:extract_plan_name_from_subscription).and_return('starter')

        stripe_event_service.new.perform(event: event)

        # Verify account attributes were updated with self-hosted plan
        expect(account.reload.custom_attributes).to include(
          'plan_name' => 'starter',
          'subscription_status' => 'active'
        )
      end
    end
  end

  describe 'subscription deletion handling' do
    it 'downgrades account to free plan on subscription deletion' do
      # Set up account with a paid plan and features
      account.update!(custom_attributes: account.custom_attributes.merge({
                                                                           'plan_name' => 'starter',
                                                                           'subscription_status' => 'active'
                                                                         }))
      account.enable_features('inbound_emails', 'help_center', 'agent_management')
      account.save!

      # Verify features are enabled
      expect(account).to be_feature_enabled('inbound_emails')
      expect(account).to be_feature_enabled('help_center')

      allow(event).to receive(:type).and_return('customer.subscription.deleted')
      # Mock end-of-period cancellation (no ended_at)
      allow(subscription).to receive(:[]).with('ended_at').and_return(nil)
      allow(subscription).to receive(:[]).with('canceled_at').and_return(1_719_414_000)
      allow(subscription).to receive(:[]).with('cancel_at_period_end').and_return(true)

      stripe_event_service.new.perform(event: event)

      account.reload

      # Verify account was downgraded to free plan
      expect(account.custom_attributes['plan_name']).to eq('free')
      expect(account.custom_attributes['subscription_status']).to eq('cancelled') # End-of-period cancellation
      expect(account.custom_attributes['canceled_at']).to eq(1_719_414_000)
      expect(account.custom_attributes['cancel_at_period_end']).to eq(true)
      expect(account.custom_attributes['ended_at']).to be_nil

      # Verify premium features were disabled
      expect(account).not_to be_feature_enabled('inbound_emails')
      expect(account).not_to be_feature_enabled('help_center')
      expect(account).not_to be_feature_enabled('agent_management')
    end

    it 'sets subscription_status to inactive for immediate cancellations' do
      # Set up account with a paid plan
      account.update!(custom_attributes: account.custom_attributes.merge({
                                                                           'plan_name' => 'professional',
                                                                           'subscription_status' => 'active'
                                                                         }))
      account.enable_features('sla', 'custom_roles')
      account.save!

      allow(event).to receive(:type).and_return('customer.subscription.deleted')
      # Mock immediate cancellation (has ended_at)
      allow(subscription).to receive(:[]).with('ended_at').and_return(1_719_415_000)
      allow(subscription).to receive(:[]).with('canceled_at').and_return(1_719_414_000)
      allow(subscription).to receive(:[]).with('cancel_at_period_end').and_return(false)

      stripe_event_service.new.perform(event: event)

      account.reload

      # Verify account status is set to inactive for immediate cancellation
      expect(account.custom_attributes['subscription_status']).to eq('inactive')
      expect(account.custom_attributes['ended_at']).to eq(1_719_415_000)
      expect(account.custom_attributes['canceled_at']).to eq(1_719_414_000)
      expect(account.custom_attributes['cancel_at_period_end']).to eq(false)

      # Verify features were still disabled
      expect(account).not_to be_feature_enabled('sla')
      expect(account).not_to be_feature_enabled('custom_roles')
    end

    it 'preserves manually managed features during downgrade' do
      # Set up account with paid plan and manually managed features
      account.update!(custom_attributes: account.custom_attributes.merge({
                                                                           'plan_name' => 'professional',
                                                                           'subscription_status' => 'active'
                                                                         }))
      account.enable_features('sla', 'custom_roles', 'inbound_emails')
      account.save!

      # Mock manually managed features
      internal_attrs_service = instance_double(Internal::Accounts::InternalAttributesService)
      allow(Internal::Accounts::InternalAttributesService).to receive(:new).with(account).and_return(internal_attrs_service)
      allow(internal_attrs_service).to receive(:manually_managed_features).and_return(['sla'])

      allow(event).to receive(:type).and_return('customer.subscription.deleted')
      allow(subscription).to receive(:[]).with('ended_at').and_return(nil)
      allow(subscription).to receive(:[]).with('canceled_at').and_return(1_719_414_000)
      allow(subscription).to receive(:[]).with('cancel_at_period_end').and_return(true)

      stripe_event_service.new.perform(event: event)

      account.reload

      # Verify manually managed features are preserved
      expect(account).to be_feature_enabled('sla')
      # But plan-based features are disabled
      expect(account).not_to be_feature_enabled('custom_roles')
      expect(account).not_to be_feature_enabled('inbound_emails')
    end
  end

  describe 'plan-specific feature management' do
    context 'with default plan (Hacker/Free)' do
      it 'disables all premium features' do
        allow(subscription).to receive(:[]).with('plan')
                                           .and_return({ 'id' => 'test', 'product' => 'plan_id_hacker', 'name' => 'Hacker' })

        # Enable some premium features first
        account.enable_features('sla', 'custom_roles', 'audit_logs')
        account.save!

        account.reload
        expect(account).to be_feature_enabled('sla')

        stripe_event_service.new.perform(event: event)

        account.reload

        # Premium features should be disabled
        expect(account).not_to be_feature_enabled('sla')
        expect(account).not_to be_feature_enabled('custom_roles')
        expect(account).not_to be_feature_enabled('audit_logs')
      end
    end

    context 'with Starter plan' do
      it 'enables starter tier features but not premium features' do
        allow(subscription).to receive(:[]).with('plan')
                                           .and_return({ 'id' => 'test', 'product' => 'plan_id_startups', 'name' => 'Startups' })

        stripe_event_service.new.perform(event: event)

        account.reload

        # Starter tier features should be enabled
        expect(account).to be_feature_enabled('agent_management')
        expect(account).to be_feature_enabled('inbound_emails')
        expect(account).to be_feature_enabled('help_center')

        # But professional and enterprise features should be disabled
        expect(account).not_to be_feature_enabled('sla')
        expect(account).not_to be_feature_enabled('custom_roles')
        expect(account).not_to be_feature_enabled('audit_logs')
        expect(account).not_to be_feature_enabled('disable_branding')
      end
    end

    context 'with Professional plan' do
      it 'enables professional-specific features' do
        allow(subscription).to receive(:[]).with('plan')
                                           .and_return({ 'id' => 'test', 'product' => 'plan_id_business', 'name' => 'Business' })

        stripe_event_service.new.perform(event: event)

        account.reload

        # Starter tier features should be enabled
        expect(account).to be_feature_enabled('agent_management')
        expect(account).to be_feature_enabled('inbound_emails')

        # Professional tier features should be enabled
        expect(account).to be_feature_enabled('sla')
        expect(account).to be_feature_enabled('custom_roles')

        # But enterprise features should be disabled
        expect(account).not_to be_feature_enabled('audit_logs')
        expect(account).not_to be_feature_enabled('disable_branding')
      end
    end

    context 'with Enterprise plan' do
      it 'enables all features including enterprise' do
        allow(subscription).to receive(:[]).with('plan')
                                           .and_return({ 'id' => 'test', 'product' => 'plan_id_enterprise', 'name' => 'Enterprise' })

        stripe_event_service.new.perform(event: event)

        account.reload

        # All tiers should be enabled
        expect(account).to be_feature_enabled('agent_management') # starter
        expect(account).to be_feature_enabled('sla') # professional
        expect(account).to be_feature_enabled('audit_logs') # enterprise
        expect(account).to be_feature_enabled('disable_branding') # enterprise
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
        expect(account).not_to be_feature_enabled('sla')
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

    context 'when downgrading from Enterprise to Professional plan' do
      before do
        # Start with Enterprise plan
        allow(subscription).to receive(:[]).with('plan')
                                           .and_return({ 'id' => 'test', 'product' => 'plan_id_enterprise', 'name' => 'Enterprise' })
        service.perform(event: event)
        account.reload
      end

      it 'retains professional features but disables enterprise features' do
        # Verify enterprise features were enabled
        expect(account).to be_feature_enabled('audit_logs')

        # Downgrade to Professional plan
        allow(subscription).to receive(:[]).with('plan')
                                           .and_return({ 'id' => 'test', 'product' => 'plan_id_business', 'name' => 'Business' })
        service.perform(event: event)

        account.reload
        expect(account).to be_feature_enabled('sla')
        expect(account).to be_feature_enabled('custom_roles')
        expect(account).not_to be_feature_enabled('audit_logs')
        expect(account).not_to be_feature_enabled('disable_branding')
      end
    end

    context 'when downgrading from Professional to Starter plan' do
      before do
        # Start with Professional plan
        allow(subscription).to receive(:[]).with('plan')
                                           .and_return({ 'id' => 'test', 'product' => 'plan_id_business', 'name' => 'Business' })
        service.perform(event: event)
        account.reload
      end

      it 'retains starter features but disables professional features' do
        # Verify professional features were enabled
        expect(account).to be_feature_enabled('sla')

        # Downgrade to Starter plan
        allow(subscription).to receive(:[]).with('plan')
                                           .and_return({ 'id' => 'test', 'product' => 'plan_id_startups', 'name' => 'Startups' })
        service.perform(event: event)

        account.reload
        # Starter features should remain
        expect(account).to be_feature_enabled('agent_management')
        expect(account).to be_feature_enabled('inbound_emails')
        # Professional features should be disabled
        expect(account).not_to be_feature_enabled('sla')
        expect(account).not_to be_feature_enabled('custom_roles')
      end
    end

    context 'when downgrading from Starter to Free plan' do
      before do
        # Start with Starter plan
        allow(subscription).to receive(:[]).with('plan')
                                           .and_return({ 'id' => 'test', 'product' => 'plan_id_startups', 'name' => 'Startups' })
        service.perform(event: event)
        account.reload
      end

      it 'disables all premium features' do
        # Verify starter features were enabled
        expect(account).to be_feature_enabled('inbound_emails')

        # Downgrade to Hacker (default) plan
        allow(subscription).to receive(:[]).with('plan')
                                           .and_return({ 'id' => 'test', 'product' => 'plan_id_hacker', 'name' => 'Hacker' })
        service.perform(event: event)

        account.reload
        # All premium features should be disabled
        expect(account).not_to be_feature_enabled('inbound_emails')
        expect(account).not_to be_feature_enabled('help_center')
        expect(account).not_to be_feature_enabled('sla')
      end
    end
  end

  describe 'plan mapping' do
    let(:service) { stripe_event_service.new }

    it 'correctly maps cloud plan names to billing plan names' do
      # Test exact matches
      expect(service.send(:map_cloud_plan_to_billing_plan, 'Free')).to eq('free')
      expect(service.send(:map_cloud_plan_to_billing_plan, 'Starter')).to eq('starter')
      expect(service.send(:map_cloud_plan_to_billing_plan, 'Professional')).to eq('professional')
      expect(service.send(:map_cloud_plan_to_billing_plan, 'Enterprise')).to eq('enterprise')
    end

    it 'handles plan names with additional words (case insensitive)' do
      # Test Stripe-style plan names with additional words
      expect(service.send(:map_cloud_plan_to_billing_plan, 'Starter Plan')).to eq('starter')
      expect(service.send(:map_cloud_plan_to_billing_plan, 'starter plan')).to eq('starter')
      expect(service.send(:map_cloud_plan_to_billing_plan, 'Professional Plan')).to eq('professional')
      expect(service.send(:map_cloud_plan_to_billing_plan, 'Enterprise Plan')).to eq('enterprise')
      expect(service.send(:map_cloud_plan_to_billing_plan, 'Free Trial')).to eq('free')
    end

    it 'handles different case variations' do
      expect(service.send(:map_cloud_plan_to_billing_plan, 'STARTER')).to eq('starter')
      expect(service.send(:map_cloud_plan_to_billing_plan, 'professional')).to eq('professional')
      expect(service.send(:map_cloud_plan_to_billing_plan, 'EnTeRpRiSe')).to eq('enterprise')
    end

    it 'returns default for unknown plan names' do
      expect(service.send(:map_cloud_plan_to_billing_plan, 'Unknown')).to eq('starter')
      expect(service.send(:map_cloud_plan_to_billing_plan, 'Random Plan')).to eq('starter')
    end

    it 'handles nil and empty inputs gracefully' do
      expect(service.send(:map_cloud_plan_to_billing_plan, nil)).to eq('starter')
      expect(service.send(:map_cloud_plan_to_billing_plan, '')).to eq('starter')
    end
  end

  describe 'installation type detection' do
    let(:service) { stripe_event_service.new }

    it 'detects cloud installation when CHATWOOT_CLOUD_PLANS config exists' do
      expect(service.send(:cloud_installation?)).to be true
    end

    it 'detects self-hosted installation when no cloud plans config exists' do
      InstallationConfig.find_by(name: 'CHATWOOT_CLOUD_PLANS')&.destroy
      expect(service.send(:cloud_installation?)).to be false
    end
  end

  describe 'free plan detection' do
    let(:service) { stripe_event_service.new }

    it 'correctly identifies free plans' do
      expect(service.send(:is_free_plan?, 'free')).to be true
      expect(service.send(:is_free_plan?, 'Free')).to be true
      expect(service.send(:is_free_plan?, nil)).to be true
      expect(service.send(:is_free_plan?, '')).to be true
      expect(service.send(:is_free_plan?, 'starter')).to be false
    end
  end
end
