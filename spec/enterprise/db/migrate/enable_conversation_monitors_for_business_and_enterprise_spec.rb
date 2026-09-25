require 'rails_helper'
require Rails.root.join('db/migrate/20260925200000_enable_conversation_monitors_for_business_and_enterprise').to_s

RSpec.describe EnableConversationMonitorsForBusinessAndEnterprise do
  before { allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true) }

  it 'enables existing Stripe Business and Enterprise accounts while preserving earlier pilot grants' do
    business = create(:account, custom_attributes: { 'plan_name' => 'Business' })
    enterprise = create(:account, custom_attributes: { 'plan_name' => 'Enterprise' })
    startup = create(:account, custom_attributes: { 'plan_name' => 'Startups' })
    pilot = create(:account, custom_attributes: { 'plan_name' => 'Startups' })
    pilot.enable_features!('conversation_monitors')
    business_pilot = create(:account, custom_attributes: { 'plan_name' => 'Business' })
    business_pilot.enable_features!('conversation_monitors')
    shopify = create(
      :account,
      internal_attributes: { 'billing_provider' => 'shopify' },
      custom_attributes: { 'plan_name' => 'Business' }
    )

    described_class.new.up

    expect(business.reload).to be_feature_enabled('conversation_monitors')
    expect(enterprise.reload).to be_feature_enabled('conversation_monitors')
    expect(startup.reload).not_to be_feature_enabled('conversation_monitors')
    expect(pilot.reload.internal_attributes['manually_managed_features']).to include('conversation_monitors')
    expect(business_pilot.reload.internal_attributes['manually_managed_features']).to include('conversation_monitors')
    expect(shopify.reload).not_to be_feature_enabled('conversation_monitors')
  end

  it 'does not change self-hosted accounts' do
    allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(false)
    business = create(:account, custom_attributes: { 'plan_name' => 'Business' })

    described_class.new.up

    expect(business.reload).not_to be_feature_enabled('conversation_monitors')
  end
end
