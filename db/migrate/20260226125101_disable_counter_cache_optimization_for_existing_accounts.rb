# counter_cache_optimization reclaims the deprecated channel_twitter bit (position 4).
# channel_twitter was enabled: true, so all existing accounts have bit 4 set to 1.
# counter_cache_optimization is enabled: false, so we must clear bit 4 for all accounts.
class DisableCounterCacheOptimizationForExistingAccounts < ActiveRecord::Migration[7.0]
  def up
    Account.feature_counter_cache_optimization.find_each(batch_size: 100) do |account|
      account.disable_features(:counter_cache_optimization)
      account.save!(validate: false)
    end
  end
end
