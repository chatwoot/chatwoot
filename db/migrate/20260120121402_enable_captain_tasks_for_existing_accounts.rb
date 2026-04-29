# Enable captain_tasks for existing accounts.
# Unlike 20250416182131_flip_chatwoot_v4_default_feature_flag_installation_config.rb,
# we don't need to update ACCOUNT_LEVEL_FEATURE_DEFAULTS or clear GlobalConfig cache
# because captain_tasks already has `enabled: true` in features.yml - ConfigLoader
# handles the defaults on deploy automatically.
class EnableCaptainTasksForExistingAccounts < ActiveRecord::Migration[7.0]
  def up
    Account.find_in_batches(batch_size: 100) do |accounts|
      accounts.each { |account| account.enable_features!('captain_tasks') }
    end
  end
end
