class RemoveMultipleFeatureFlags < ActiveRecord::Migration[6.0]
  def change
    current_config = InstallationConfig.where(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS').last
    InstallationConfig.where(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS').where.not(id: current_config.id).destroy_all
  end
end
