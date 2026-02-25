class ReclaimUnusedFeatureFlagSlots < ActiveRecord::Migration[7.0]
  def up
    feature_list = YAML.safe_load(Rails.root.join('config/features.yml').read)
    removed_names = feature_list.select { |f| f['removed'] }.pluck('name')
    return if removed_names.empty?

    Account.find_in_batches(batch_size: 1000) do |accounts|
      accounts.each { |account| account.disable_features!(*removed_names) }
    end
  end
end
