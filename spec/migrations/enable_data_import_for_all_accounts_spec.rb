require 'rails_helper'
require Rails.root.join('db/migrate/20261103142055_enable_data_import_for_all_accounts')

RSpec.describe EnableDataImportForAllAccounts do
  let(:migration) { described_class.new }
  let(:other_default) { { 'name' => 'labels', 'enabled' => false } }
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
    enabled_account = create(:account)
    enabled_account.enable_features!('data_import', 'api_and_webhooks')
    disabled_account = create(:account)

    migration.up
    migration.up

    expect(enabled_account.reload).to be_feature_enabled('data_import')
    expect(enabled_account).to be_feature_enabled('api_and_webhooks')
    expect(disabled_account.reload).to be_feature_enabled('data_import')
    expect(config.reload.value.count { |feature| feature['name'] == 'data_import' }).to eq(1)
  end

  it 'preserves an operator-disabled flag when rolling back' do
    account = create(:account)
    migration.up
    account.reload.disable_features!('data_import')

    migration.down

    expect(account.reload).not_to be_feature_enabled('data_import')
  end
end
