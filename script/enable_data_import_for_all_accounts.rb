# Run once from the production Rails console after deploying plan-independent data imports:
#   load Rails.root.join('script/enable_data_import_for_all_accounts.rb')
# This also updates the persisted default for new accounts on existing installations.
# Running it again will re-enable accounts manually disabled since the rollout.

defaults = InstallationConfig.find_by!(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')
defaults.with_lock do
  features = defaults.value
  features.find { |feature| feature['name'] == 'data_import' }['enabled'] = true
  defaults.update!(value: features)
end

updated_accounts = 0
Account.not_feature_data_import.in_batches do |batch|
  # Update only this bit so concurrent changes to other feature flags remain intact.
  updated_accounts += batch.update_all(Account.set_feature_data_import_sql) # rubocop:disable Rails/SkipsModelValidations
end

puts "Enabled data import for #{updated_accounts} existing accounts and enabled the default for new accounts."
