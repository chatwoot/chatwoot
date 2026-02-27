# counter_cache_optimization reclaims the deprecated channel_twitter bit (position 4).
# channel_twitter was enabled: true, so all existing accounts have bit 4 set to 1.
# counter_cache_optimization is enabled: false, so we must clear bit 4 for all accounts.
class DisableCounterCacheOptimizationForExistingAccounts < ActiveRecord::Migration[7.0]
  def up
    Account.find_in_batches(batch_size: 100) do |accounts|
      accounts.each { |account| account.disable_features!(:counter_cache_optimization) }
    end
  end
end
