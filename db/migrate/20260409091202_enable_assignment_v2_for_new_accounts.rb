class EnableAssignmentV2ForNewAccounts < ActiveRecord::Migration[7.1]
  def up
    config = InstallationConfig.find_by(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')
    return if config&.value.blank?

    features = config.value
    feature = features.find { |f| f['name'] == 'assignment_v2' }
    return if feature.blank?

    feature['enabled'] = true
    config.update!(value: features)
    GlobalConfig.clear_cache
  end
end
