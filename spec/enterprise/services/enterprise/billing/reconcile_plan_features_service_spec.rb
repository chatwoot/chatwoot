require 'rails_helper'

describe Enterprise::Billing::ReconcilePlanFeaturesService do
  let(:account) { create(:account) }

  before do
    create(:installation_config, {
             name: 'CHATWOOT_CLOUD_PLANS',
             value: [
               { 'name' => 'Hacker', 'product_id' => ['plan_id_hacker'], 'price_ids' => ['price_hacker'] },
               { 'name' => 'Startups', 'product_id' => ['plan_id_startups'], 'price_ids' => ['price_startups'] }
             ]
           })
  end

  describe '#perform' do
    context 'with api_and_webhooks feature' do
      it 'enables the feature for a paid plan with an active subscription' do
        account.update!(custom_attributes: { 'plan_name' => 'Startups', 'subscription_status' => 'active' })

        described_class.new(account: account).perform

        expect(account.reload).to be_feature_enabled('api_and_webhooks')
      end

      it 'enables the feature for a paid plan on trial' do
        account.update!(custom_attributes: { 'plan_name' => 'Startups', 'subscription_status' => 'trialing' })

        described_class.new(account: account).perform

        expect(account.reload).to be_feature_enabled('api_and_webhooks')
      end

      it 'disables the feature on the default plan' do
        account.enable_features!('api_and_webhooks')
        account.update!(custom_attributes: { 'plan_name' => 'Hacker', 'subscription_status' => 'active' })

        described_class.new(account: account).perform

        expect(account.reload).not_to be_feature_enabled('api_and_webhooks')
      end

      it 'keeps the feature enabled when manually managed' do
        account.update!(custom_attributes: { 'plan_name' => 'Hacker', 'subscription_status' => 'trialing' })
        Internal::Accounts::InternalAttributesService.new(account).manually_managed_features = ['api_and_webhooks']

        described_class.new(account: account).perform

        expect(account.reload).to be_feature_enabled('api_and_webhooks')
      end
    end

    context 'with a Shopify-billed account' do
      let(:account) do
        create(
          :account,
          internal_attributes: { 'billing_provider' => 'shopify' },
          custom_attributes: { 'plan_name' => 'Shopify Basic' }
        )
      end
      let(:shopify_plans) do
        [
          {
            'name' => 'Shopify Basic',
            'handle' => 'shopify-basic',
            'features' => %w[audit_logs],
            'limits' => { 'agents' => 5, 'inboxes' => 10 }
          },
          {
            'name' => 'Shopify Pro',
            'handle' => 'shopify-pro',
            'features' => %w[audit_logs saml],
            'limits' => { 'agents' => 10, 'inboxes' => 20 }
          }
        ]
      end
      let!(:shopify_config) do
        create(:installation_config, name: 'CHATWOOT_SHOPIFY_PLANS', value: shopify_plans, locked: true)
      end

      before do
        allow(GlobalConfigService).to receive(:load).and_call_original
        allow(GlobalConfigService).to receive(:load)
          .with('ENABLE_SHOPIFY_INTEGRATION', 'false')
          .and_return(true)
        account.enable_features!('shopify_integration')
      end

      it 'enables features from the Shopify plan catalog without changing the rollout flag' do
        described_class.new(account: account).perform

        expect(account.reload).to be_feature_enabled('audit_logs')
        expect(account).not_to be_feature_enabled('saml')
        expect(account).not_to be_feature_enabled('captain_integration_v2')
        expect(account).to be_feature_enabled('shopify_integration')
      end

      it 'clears default plan entitlements omitted from every Shopify plan' do
        account.enable_features!('api_and_webhooks')

        described_class.new(account: account).perform

        expect(account.reload).not_to be_feature_enabled('api_and_webhooks')
        expect(account).to be_feature_enabled('audit_logs')
      end

      it 'clears Captain V2 when it is omitted from every Shopify plan' do
        account.enable_features!('captain_integration_v2')

        described_class.new(account: account).perform

        expect(account.reload).not_to be_feature_enabled('captain_integration_v2')
        expect(account).to be_feature_enabled('audit_logs')
      end

      it 'removes features that are not present after a Shopify plan change' do
        account.update!(custom_attributes: { 'plan_name' => 'Shopify Pro' })
        described_class.new(account: account).perform
        expect(account.reload).to be_feature_enabled('saml')

        account.update!(custom_attributes: { 'plan_name' => 'Shopify Basic' })
        described_class.new(account: account).perform

        expect(account.reload).not_to be_feature_enabled('saml')
        expect(account).to be_feature_enabled('audit_logs')
      end

      it 'removes a feature that was deleted from the Shopify catalog' do
        account.update!(custom_attributes: { 'plan_name' => 'Shopify Pro' })
        described_class.new(account: account).perform
        expect(account.reload).to be_feature_enabled('saml')

        shopify_config.update!(value: [shopify_plans.first])
        account.update!(custom_attributes: { 'plan_name' => 'Shopify Basic' })
        described_class.new(account: account).perform

        expect(account.reload).not_to be_feature_enabled('saml')
        expect(account.internal_attributes['shopify_managed_features']).to contain_exactly('audit_logs')
      end

      it 'preserves a manually managed feature after it is deleted from the Shopify catalog' do
        account.update!(custom_attributes: { 'plan_name' => 'Shopify Pro' })
        Internal::Accounts::InternalAttributesService.new(account).manually_managed_features = ['saml']
        described_class.new(account: account).perform

        shopify_config.update!(value: [shopify_plans.first])
        account.update!(custom_attributes: { 'plan_name' => 'Shopify Basic' })
        described_class.new(account: account).perform

        expect(account.reload).to be_feature_enabled('saml')
        expect(account.internal_attributes['shopify_managed_features']).to contain_exactly('audit_logs')
      end

      it 'rejects an unknown Shopify plan instead of guessing entitlements' do
        account.update!(custom_attributes: { 'plan_name' => 'Unknown' })

        expect do
          described_class.new(account: account).perform
        end.to raise_error(Enterprise::Billing::PlanConfiguration::UnknownPlan)
      end

      it 'preserves entitlements when the global Shopify switch is disabled' do
        account.enable_features!('saml')
        allow(GlobalConfigService).to receive(:load)
          .with('ENABLE_SHOPIFY_INTEGRATION', 'false')
          .and_return(false)
        expect(Enterprise::Billing::PlanConfiguration).not_to receive(:plans_for)

        described_class.new(account: account).perform

        expect(account.reload).to be_feature_enabled('saml')
      end

      it 'preserves entitlements when the account Shopify flag is disabled' do
        account.enable_features!('saml')
        account.disable_features!('shopify_integration')
        expect(Enterprise::Billing::PlanConfiguration).not_to receive(:plans_for)

        described_class.new(account: account).perform

        expect(account.reload).to be_feature_enabled('saml')
      end
    end
  end
end
