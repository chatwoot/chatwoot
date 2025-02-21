module SuperAdmin::AccountFeaturesHelper
  def self.account_features
    YAML.safe_load(Rails.root.join('config/features.yml').read).freeze
  end

  def self.account_premium_features
    account_features.filter { |feature| feature['premium'] }.pluck('name')
  end

  # Returns a hash mapping feature names to their display names
  def self.feature_display_names
    account_features.each_with_object({}) do |feature, hash|
      hash[feature['name']] = feature['display_name']
    end
  end

  # Accepts account.features as argument
  def self.filtered_features(features)
    deployment_env = GlobalConfig.get_value('DEPLOYMENT_ENV')
    filtered = if deployment_env == 'cloud'
                 features
               else
                 # Filter out internal features for non-cloud environments
                 internal_features = account_features.select { |f| f['chatwoot_internal'] }.pluck('name')
                 features.except(*internal_features)
               end

    # Get display names for sorting
    display_names = feature_display_names

    # Sort and add features (regular first, then premium)
    regular, premium = filtered.partition { |key, _value| account_premium_features.exclude?(key) }

    # Sort each category by display name
    regular_sorted = regular.sort_by { |key, _| display_names[key] || key }.to_h
    premium_sorted = premium.sort_by { |key, _| display_names[key] || key }.to_h

    # Return the combined hash with display names
    regular_sorted.transform_keys { |key| [key, display_names[key]] }
                  .merge(premium_sorted.transform_keys { |key| [key, display_names[key]] })
  end
end
