require 'rake'
require 'rails_helper'

load Rails.root.join('enterprise/lib/tasks/billing_features.rake')

RSpec.describe Rake::Task do
  let(:task) { described_class['billing:reconcile_classifier_and_monitors'] }

  before do
    task.reenable
    InstallationConfig.find_or_initialize_by(name: 'CHATWOOT_CLOUD_PLANS').update!(
      value: [{ 'name' => 'Hacker' }, { 'name' => 'Startups' }, { 'name' => 'Business' }]
    )
    InstallationConfig.find_or_initialize_by(name: 'CHATWOOT_SHOPIFY_PLANS').update!(
      value: [
        { 'name' => 'Shopify Basic', 'handle' => 'shopify-basic', 'features' => [], 'limits' => { 'agents' => 5, 'inboxes' => 10 } },
        { 'name' => 'Shopify Pro', 'handle' => 'shopify-pro', 'features' => %w[conversation_monitors],
          'limits' => { 'agents' => 10, 'inboxes' => 20 } }
      ], locked: true
    )
    InstallationConfig.find_or_initialize_by(name: 'ENABLE_SHOPIFY_INTEGRATION').update!(value: true)
  end

  it 'removes stale monitor grants from lower paid plans and retains classifier access' do
    startup = create(:account, custom_attributes: { 'plan_name' => 'Startups' })
    startup.enable_features!('conversation_monitors')
    business = create(:account, custom_attributes: { 'plan_name' => 'Business' })
    basic = create(:account, internal_attributes: { 'billing_provider' => 'shopify', 'signup_source' => 'shopify' },
                             custom_attributes: { 'plan_name' => 'Shopify Basic', 'subscription_status' => 'active' })
    basic.enable_features!('shopify_integration', 'conversation_monitors')
    pro = create(:account, internal_attributes: { 'billing_provider' => 'shopify', 'signup_source' => 'shopify' },
                           custom_attributes: { 'plan_name' => 'Shopify Pro', 'subscription_status' => 'active' })
    pro.enable_features!('shopify_integration')

    task.invoke

    expect(startup.reload).not_to be_feature_enabled('conversation_monitors')
    expect(startup).to be_feature_enabled('captain_classifier')
    expect(business.reload).to be_feature_enabled('conversation_monitors')
    expect(basic.reload).not_to be_feature_enabled('conversation_monitors')
    expect(basic).to be_feature_enabled('captain_classifier')
    expect(pro.reload).to be_feature_enabled('conversation_monitors')
    expect(pro).to be_feature_enabled('captain_classifier')
  end

  it 'removes stale free grants but skips unverified Shopify accounts' do
    hacker = create(:account, custom_attributes: { 'plan_name' => 'Hacker' })
    hacker.enable_features!('conversation_monitors')
    pending = create(:account, internal_attributes: { 'billing_provider' => 'shopify', 'signup_source' => 'shopify' },
                               custom_attributes: { 'plan_name' => 'Shopify Basic', 'subscription_status' => 'pending' })
    pending.enable_features!('shopify_integration')

    task.invoke

    expect(hacker.reload).not_to be_feature_enabled('conversation_monitors')
    expect(pending.reload).not_to be_feature_enabled('captain_classifier')
  end

  it 'preserves explicit manual monitor grants when repeated' do
    startup = create(:account, custom_attributes: { 'plan_name' => 'Startups' })
    Internal::Accounts::InternalAttributesService.new(startup).manually_managed_features = ['conversation_monitors']

    task.invoke
    task.reenable
    task.invoke

    expect(startup.reload).to be_feature_enabled('conversation_monitors')
    expect(startup).to be_feature_enabled('captain_classifier')
  end
end
