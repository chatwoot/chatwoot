module SuperAdmin::AccountFeaturesHelper
  def self.account_features
    YAML.safe_load(Rails.root.join('config/features.yml').read).freeze
  end

  def self.account_premium_features
    account_features.filter { |feature| feature['premium'] }.pluck('name')
  end

  # Accepts account.features as argument
  def self.filtered_features(features)
    deployment_env = GlobalConfig.get_value('DEPLOYMENT_ENV')
    return features if deployment_env == 'cloud'

    # Filter out internal features for non-cloud environments
    internal_features = account_features.select { |f| f['chatwoot_internal'] }.pluck('name')
    features.except(*internal_features)
  end
end
