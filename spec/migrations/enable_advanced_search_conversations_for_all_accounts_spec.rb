require 'rails_helper'
require Rails.root.join('db/migrate/20261124190840_enable_advanced_search_conversations_for_all_accounts')

RSpec.describe EnableAdvancedSearchConversationsForAllAccounts do
  subject(:migrate) { described_class.new.up }

  it 'enables existing accounts without changing other flags or metadata' do
    account = create(:account, internal_attributes: { 'example' => 'retained' })
    account.enable_features!('data_import', 'inbound_emails')
    account.disable_features!('advanced_search_conversations')
    original_flags = account.all_features.except('advanced_search_conversations')

    migrate

    expect(account.reload.feature_enabled?('advanced_search_conversations')).to be(true)
    expect(account.all_features.except('advanced_search_conversations')).to eq(original_flags)
    expect(account.internal_attributes).to eq('example' => 'retained')
  end

  it 'updates the stored default for new accounts and preserves other defaults' do
    defaults = [{ name: 'advanced_search_conversations', enabled: false }, { name: 'data_import', enabled: false }]
    config = InstallationConfig.create!(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS', value: defaults)
    migrate
    migrate

    expect(config.reload.value.count { |feature| feature['name'] == 'advanced_search_conversations' }).to eq(1)
    account = create(:account)
    expect(account.feature_enabled?('advanced_search_conversations')).to be(true)
    expect(account.feature_enabled?('data_import')).to be(false)
  end

  it 'sets up missing defaults and leaves an explicit account opt-out usable afterward' do
    migrate
    account = create(:account)
    expect(account.feature_enabled?('advanced_search_conversations')).to be(true)

    account.disable_features!('advanced_search_conversations')
    expect(account.reload.feature_enabled?('advanced_search_conversations')).to be(false)
  end
end
