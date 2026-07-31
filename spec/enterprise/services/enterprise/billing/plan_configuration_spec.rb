require 'rails_helper'

RSpec.describe Enterprise::Billing::PlanConfiguration do
  let(:stripe_plans) do
    [
      {
        'name' => 'Hacker',
        'product_id' => ['stripe-product'],
        'price_ids' => ['stripe-price']
      }
    ]
  end
  let(:shopify_plans) do
    [
      {
        'name' => 'Shopify Basic',
        'handle' => 'shopify-basic',
        'features' => %w[help_center campaigns],
        'limits' => {
          'agents' => 5,
          'inboxes' => 10,
          'emails' => 500,
          'captain_documents' => 25,
          'captain_responses' => 100
        }
      }
    ]
  end

  before do
    create(:installation_config, name: 'CHATWOOT_CLOUD_PLANS', value: stripe_plans)
    create(:installation_config, name: 'CHATWOOT_SHOPIFY_PLANS', value: shopify_plans, locked: true)
  end

  it 'keeps Stripe as the default provider configuration' do
    expect(described_class.plans).to eq(stripe_plans)
    expect(described_class.default_plan).to eq(stripe_plans.first)
  end

  it 'loads plans for the account billing provider' do
    account = create(:account, internal_attributes: { 'billing_provider' => 'shopify' })

    expect(described_class.plans_for(account)).to eq(shopify_plans)
  end

  it 'raises when the locked Shopify plan catalog is missing' do
    InstallationConfig.find_by!(name: 'CHATWOOT_SHOPIFY_PLANS').destroy!

    expect do
      described_class.plans(provider: 'shopify')
    end.to raise_error(ActiveRecord::RecordNotFound)
  end

  it 'raises when the locked Shopify plan catalog is empty' do
    InstallationConfig.find_by!(name: 'CHATWOOT_SHOPIFY_PLANS').update!(value: [])

    expect do
      described_class.plans(provider: 'shopify')
    end.to raise_error(described_class::InvalidConfiguration, 'CHATWOOT_SHOPIFY_PLANS must contain at least one plan')
  end

  it 'finds the current Shopify plan by its Chatwoot plan name' do
    account = create(
      :account,
      internal_attributes: { 'billing_provider' => 'shopify' },
      custom_attributes: { 'plan_name' => 'Shopify Basic' }
    )

    expect(described_class.current_plan(account)).to eq(shopify_plans.first)
  end

  it 'finds a Shopify plan by its verified handle' do
    expect(described_class.find_shopify_plan_by_handle('shopify-basic')).to eq(shopify_plans.first)
    expect(described_class.find_shopify_plan_by_handle('unknown')).to be_nil
  end

  it 'rejects unsupported providers' do
    expect do
      described_class.plans(provider: 'unsupported')
    end.to raise_error(ArgumentError, 'Unsupported billing provider: unsupported')
  end

  it 'rejects a non-array Shopify catalog' do
    InstallationConfig.find_by!(name: 'CHATWOOT_SHOPIFY_PLANS').update!(value: {})

    expect do
      described_class.plans(provider: 'shopify')
    end.to raise_error(described_class::InvalidConfiguration, 'CHATWOOT_SHOPIFY_PLANS must be an array')
  end

  it 'rejects Shopify plans without required limits' do
    shopify_plans.first['limits'].delete('agents')
    InstallationConfig.find_by!(name: 'CHATWOOT_SHOPIFY_PLANS').update!(value: shopify_plans)

    expect do
      described_class.plans(provider: 'shopify')
    end.to raise_error(described_class::InvalidConfiguration, /limits is missing required limits/)
  end

  it 'rejects unknown Shopify plan features' do
    shopify_plans.first['features'] = ['unknown_feature']
    InstallationConfig.find_by!(name: 'CHATWOOT_SHOPIFY_PLANS').update!(value: shopify_plans)

    expect do
      described_class.plans(provider: 'shopify')
    end.to raise_error(described_class::InvalidConfiguration, /features contains unknown features/)
  end

  it 'keeps the Shopify rollout flag outside plan reconciliation' do
    shopify_plans.first['features'] = [Shopify::FeatureGate::ACCOUNT_FEATURE]
    InstallationConfig.find_by!(name: 'CHATWOOT_SHOPIFY_PLANS').update!(value: shopify_plans)

    expect do
      described_class.plans(provider: 'shopify')
    end.to raise_error(described_class::InvalidConfiguration, /features cannot manage shopify_integration/)
  end

  it 'rejects duplicate Shopify handles' do
    shopify_plans << shopify_plans.first.merge('name' => 'Shopify Pro')
    InstallationConfig.find_by!(name: 'CHATWOOT_SHOPIFY_PLANS').update!(value: shopify_plans)

    expect do
      described_class.plans(provider: 'shopify')
    end.to raise_error(described_class::InvalidConfiguration, /duplicate handle values/)
  end
end
