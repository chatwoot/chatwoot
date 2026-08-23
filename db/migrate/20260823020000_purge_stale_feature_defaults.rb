class PurgeStaleFeatureDefaults < ActiveRecord::Migration[7.2]
  def up
    # The ACCOUNT_LEVEL_FEATURE_DEFAULTS config accumulates stale entries (e.g.
    # agent_bots) whenever a feature flag is removed from config/features.yml.
    # Leaving them breaks account creation: Featurable#enable_default_features
    # tries to call feature_<name>= which no longer exists.
    valid_names = YAML.safe_load(Rails.root.join('config/features.yml').read).pluck('name')

    config = InstallationConfig.find_by(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')
    return if config.blank? || config.value.blank?

    stale_names = config.value.pluck('name') - valid_names
    return if stale_names.empty?

    config.value = config.value.reject { |f| stale_names.include?(f['name']) }
    config.save!
    GlobalConfig.clear_cache
  end

  def down
    # No-op: removed stale entries cannot be faithfully restored.
  end
end
