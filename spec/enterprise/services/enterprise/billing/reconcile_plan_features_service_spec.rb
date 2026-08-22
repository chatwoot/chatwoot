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
  end
end
