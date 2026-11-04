require 'rails_helper'
require Rails.root.join('db/migrate/20261103142055_enable_data_import_for_all_accounts')

RSpec.describe EnableDataImportForAllAccounts do
  let(:migration) { described_class.new }
  let(:other_default) { { 'name' => 'labels', 'enabled' => false } }
  let(:shopify_plans) do
    [
      {
        'name' => 'Shopify Basic', 'handle' => 'shopify-basic',
        'features' => %w[data_import audit_logs], 'limits' => { 'agents' => 5, 'inboxes' => 10 }
      },
      {
        'name' => 'Shopify Pro', 'handle' => 'shopify-pro',
        'features' => %w[saml data_import], 'limits' => { 'agents' => 10, 'inboxes' => 20 }
      }
    ]
  end
  let!(:config) do
    create(:installation_config, name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS', value: [other_default, { 'name' => 'data_import', 'enabled' => false }])
  end

  it 'enables existing and new accounts without changing unrelated flags or defaults' do
    account = create(:account)
    account.enable_features!('whatsapp_manual_transfer')
    original_flags = account.feature_flags

    migration.up

    expect(account.reload).to be_feature_enabled('data_import')
    expect(account).to be_feature_enabled('whatsapp_manual_transfer')
    expect(account.feature_flags).to eq(original_flags)
    expect(config.reload.value).to include(other_default)
    expect(config.value.find { |feature| feature['name'] == 'data_import' }).to include('enabled' => true, 'column' => 'feature_flags_ext_1')
    expect(create(:account)).to be_feature_enabled('data_import')
  end

  it 'adds the default when an installation skipped the release that introduced the flag' do
    config.update!(value: [other_default])

    migration.up

    expect(config.reload.value).to include(other_default, a_hash_including('name' => 'data_import', 'enabled' => true))
    expect(create(:account)).to be_feature_enabled('data_import')
  end

  it 'creates the stored defaults when migrating a fresh installation before the config loader runs' do
    config.destroy!

    migration.up

    defaults = InstallationConfig.find_by!(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')
    expect(defaults.value).to include(a_hash_including('name' => 'data_import', 'enabled' => true))
    expect(create(:account)).to be_feature_enabled('data_import')
  end

  it 'can resume a partially completed backfill without changing other feature settings' do
    enabled_account = create(:account, internal_attributes: { 'manually_managed_features' => %w[data_import audit_logs] })
    enabled_account.enable_features!('data_import', 'api_and_webhooks')
    disabled_account = create(:account)

    migration.up
    migration.up

    expect(enabled_account.reload).to be_feature_enabled('data_import')
    expect(enabled_account).to be_feature_enabled('api_and_webhooks')
    expect(disabled_account.reload).to be_feature_enabled('data_import')
    expect(config.reload.value.count { |feature| feature['name'] == 'data_import' }).to eq(1)
    expect(enabled_account.internal_attributes['manually_managed_features']).to eq(%w[audit_logs])
  end

  it 'removes data import from every Shopify plan without changing other catalog values' do
    catalog = create(:installation_config, name: 'CHATWOOT_SHOPIFY_PLANS', value: shopify_plans)

    migration.up

    expected_plans = [
      shopify_plans.first.merge('features' => %w[audit_logs]),
      shopify_plans.second.merge('features' => %w[saml])
    ]
    expect(catalog.reload.value).to eq(expected_plans)
  end

  it 'cleans references on already-enabled accounts while preserving unrelated and absent metadata' do
    account = create(:account, internal_attributes: {
                       'shopify_managed_features' => %w[data_import audit_logs],
                       'manually_managed_features' => %w[custom_tools data_import],
                       'marketing_attribution' => { 'source' => 'docs' }
                     })
    account.enable_features!('data_import')
    partial = create(:account, internal_attributes: { 'shopify_managed_features' => %w[data_import] })
    unaffected = create(:account, internal_attributes: { 'marketing_attribution' => { 'source' => 'website' } })
    original_updated_at = unaffected.updated_at

    migration.up

    expect(account.reload.internal_attributes).to eq(
      'shopify_managed_features' => %w[audit_logs],
      'manually_managed_features' => %w[custom_tools],
      'marketing_attribution' => { 'source' => 'docs' }
    )
    expect(account).to be_feature_enabled('data_import')
    expect(partial.reload.internal_attributes).to eq('shopify_managed_features' => [])
    expect(unaffected.reload.internal_attributes).to eq('marketing_attribution' => { 'source' => 'website' })
    expect(unaffected.updated_at).to eq(original_updated_at)
  end

  it 'preserves an operator-disabled flag when rolling back' do
    account = create(:account)
    migration.up
    account.reload.disable_features!('data_import')

    migration.down

    expect(account.reload).not_to be_feature_enabled('data_import')
  end
end
