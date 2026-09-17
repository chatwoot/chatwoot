require 'rails_helper'

RSpec.describe Account do
  describe '#campaign_analytics_enabled?' do
    let(:account) { build(:account) }

    context 'when self-hosted' do
      before { allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(false) }

      %w[premium enterprise].each do |plan|
        it "allows the #{plan} plan" do
          allow(ChatwootHub).to receive(:pricing_plan).and_return(plan)
          expect(account.campaign_analytics_enabled?).to be(true)
        end
      end

      it 'rejects the community plan' do
        allow(ChatwootHub).to receive(:pricing_plan).and_return('community')
        expect(account.campaign_analytics_enabled?).to be(false)
      end
    end

    context 'when on Cloud' do
      before do
        allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
        create(:installation_config, name: 'CHATWOOT_CLOUD_PLANS', value: [{ 'name' => 'Hacker' }, { 'name' => 'Startups' }])
      end

      [nil, 'Hacker', 'unknown'].each do |plan|
        it "rejects an unentitled plan #{plan.inspect}" do
          account.custom_attributes['plan_name'] = plan
          expect(account.campaign_analytics_enabled?).to be(false)
        end
      end

      it 'allows a configured Shopify subscription' do
        account.billing_provider = 'shopify'
        allow(Enterprise::Billing::PlanConfiguration).to receive(:current_plan).with(account).and_return({ 'name' => 'Basic' })
        expect(account.campaign_analytics_enabled?).to be(true)
      end

      it 'rejects Shopify accounts without a configured subscription' do
        account.billing_provider = 'shopify'
        expect(account.campaign_analytics_enabled?).to be(false)
      end
    end
  end
end
