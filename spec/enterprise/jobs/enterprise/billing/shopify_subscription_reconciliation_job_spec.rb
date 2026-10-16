require 'rails_helper'

RSpec.describe Enterprise::Billing::ShopifySubscriptionReconciliationJob do
  let(:eligible_account) do
    create(
      :account,
      internal_attributes: {
        'billing_provider' => 'shopify',
        'signup_source' => 'shopify'
      }
    )
  end
  let(:stripe_account) { create(:account) }
  let(:account_gate_disabled) do
    create(
      :account,
      internal_attributes: {
        'billing_provider' => 'shopify',
        'signup_source' => 'shopify'
      }
    )
  end

  before do
    allow(GlobalConfigService).to receive(:load).and_call_original
    allow(GlobalConfigService).to receive(:load)
      .with('ENABLE_SHOPIFY_INTEGRATION', 'false')
      .and_return(true)

    eligible_account.enable_features!('shopify_integration')
    stripe_account.enable_features!('shopify_integration')
    account_gate_disabled.enable_features!('shopify_integration')

    create(
      :integrations_hook,
      :shopify,
      account: eligible_account,
      status: :enabled,
      reference_id: 'eligible.myshopify.com'
    )
    create(
      :integrations_hook,
      :shopify,
      account: stripe_account,
      status: :enabled,
      reference_id: 'stripe.myshopify.com'
    )
    create(
      :integrations_hook,
      :shopify,
      account: account_gate_disabled,
      status: :enabled,
      reference_id: 'disabled.myshopify.com'
    )
    account_gate_disabled.disable_features!('shopify_integration')
  end

  it 'enqueues reconciliation only for enabled Shopify-billed accounts' do
    expect(Enterprise::Billing::ShopifySubscriptionSyncJob).to receive(:perform_later)
      .with(eligible_account.id)
      .once

    described_class.perform_now
  end

  it 'does not enqueue reconciliation when the global gate is disabled' do
    allow(GlobalConfigService).to receive(:load)
      .with('ENABLE_SHOPIFY_INTEGRATION', 'false')
      .and_return(false)
    expect(Enterprise::Billing::ShopifySubscriptionSyncJob).not_to receive(:perform_later)

    described_class.perform_now
  end

  it 'uses the scheduled jobs queue' do
    expect(described_class.queue_name).to eq('scheduled_jobs')
  end
end
