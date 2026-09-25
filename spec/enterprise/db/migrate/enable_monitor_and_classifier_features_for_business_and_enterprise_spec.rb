require 'rails_helper'
require Rails.root.join('db/migrate/20260925200000_enable_monitor_and_classifier_features_for_business_and_enterprise').to_s

RSpec.describe EnableMonitorAndClassifierFeaturesForBusinessAndEnterprise do
  before { allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true) }

  it 'enables both features for existing Stripe Business and Enterprise accounts' do
    business = create(:account, custom_attributes: { 'plan_name' => 'Business' })
    enterprise = create(:account, custom_attributes: { 'plan_name' => 'Enterprise' })
    startup = create(:account, custom_attributes: { 'plan_name' => 'Startups' })

    described_class.new.up

    expect(business.reload).to be_feature_enabled('conversation_monitors')
    expect(business).to be_feature_enabled('captain_classifier')
    expect(enterprise.reload).to be_feature_enabled('conversation_monitors')
    expect(enterprise).to be_feature_enabled('captain_classifier')
    expect(startup.reload).not_to be_feature_enabled('conversation_monitors')
    expect(startup).not_to be_feature_enabled('captain_classifier')
  end

  it 'preserves earlier pilot grants as manual overrides' do
    pilot = create(:account, custom_attributes: { 'plan_name' => 'Startups' })
    pilot.enable_features!('conversation_monitors', 'captain_classifier')
    business_pilot = create(:account, custom_attributes: { 'plan_name' => 'Business' })
    business_pilot.enable_features!('conversation_monitors')

    described_class.new.up

    expect(pilot.reload.internal_attributes['manually_managed_features']).to include('conversation_monitors', 'captain_classifier')
    expect(business_pilot.reload.internal_attributes['manually_managed_features']).to include('conversation_monitors')
    expect(business_pilot).to be_feature_enabled('captain_classifier')
  end

  it 'does not manage Shopify grants' do
    shopify = create(:account, internal_attributes: { 'billing_provider' => 'shopify' }, custom_attributes: { 'plan_name' => 'Business' })
    existing_grant = create(:account, internal_attributes: { 'billing_provider' => 'shopify' })
    existing_grant.enable_features!('conversation_monitors', 'captain_classifier')

    described_class.new.up

    expect(shopify.reload).not_to be_feature_enabled('conversation_monitors')
    expect(shopify).not_to be_feature_enabled('captain_classifier')
    expect(existing_grant.reload).to be_feature_enabled('conversation_monitors')
    expect(existing_grant).to be_feature_enabled('captain_classifier')
    expect(existing_grant.internal_attributes['manually_managed_features']).to be_nil
  end

  it 'does not change self-hosted accounts' do
    allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(false)
    business = create(:account, custom_attributes: { 'plan_name' => 'Business' })

    described_class.new.up

    expect(business.reload).not_to be_feature_enabled('conversation_monitors')
    expect(business).not_to be_feature_enabled('captain_classifier')
  end
end
