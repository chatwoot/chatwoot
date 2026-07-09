# Enable api_and_webhooks for existing accounts.
# Like 20260120121402_enable_captain_tasks_for_existing_accounts.rb, we don't need
# to update ACCOUNT_LEVEL_FEATURE_DEFAULTS or clear GlobalConfig cache because
# api_and_webhooks has `enabled: true` in features.yml - ConfigLoader handles the
# defaults on deploy automatically.
class EnableApiAndWebhooksForExistingAccounts < ActiveRecord::Migration[7.0]
  def up
    Account.find_in_batches(batch_size: 100) do |accounts|
      accounts.each { |account| account.enable_features!('api_and_webhooks') }
    end
  end
end
