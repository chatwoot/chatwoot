module SuperAdmin::AccountFeaturesHelper
  def self.account_features
    YAML.safe_load(Rails.root.join('config/features.yml').read).freeze
  end

  def self.account_premium_features
    account_features.filter { |feature| feature['premium'] }.pluck('name')
  end

  # The list the dashboard shows its "Learn more" links from (dashboard/helper/featureHelper.js).
  def self.feature_help_urls
    YAML.safe_load(Rails.root.join('config/feature_help_urls.yml').read).freeze
  end

  def self.feature_icons
    icons = YAML.safe_load(Rails.root.join('app/helpers/super_admin/account_feature_icons.yml').read)
    icons.default = 'i-lucide-toggle-right'
    icons.freeze
  end

  # Returns a hash mapping feature names to their display names
  def self.feature_display_names
    account_features.each_with_object({}) do |feature, hash|
      hash[feature['name']] = feature['display_name']
    end
  end

  def self.filter_internal_features(features)
    return features if ChatwootApp.chatwoot_cloud?

    internal_features = account_features.select { |f| f['chatwoot_internal'] }.pluck('name')
    features.except(*internal_features)
  end

  def self.filter_deprecated_features(features)
    deprecated_features = account_features.select { |f| f['deprecated'] }.pluck('name')
    features.except(*deprecated_features)
  end

  def self.sort_and_transform_features(features, display_names)
    features.sort_by { |key, _| display_names[key] || key }
            .to_h
            .transform_keys { |key| [key, display_names[key]] }
  end

  # Features left out of the Super Admin feature lists; they are changed from the console
  def self.hidden_features
    account_features.select { |feature| feature['hidden'] }.pluck('name')
  end

  # The form does not show hidden features, so they keep the state the account already has
  def self.with_hidden_features(flags, account)
    flags + hidden_features.select { |feature| account&.feature_enabled?(feature) }.map { |feature| :"feature_#{feature}" }
  end

  def self.partition_features(features)
    filtered = features.except(*hidden_features)
    filtered = filter_internal_features(filtered)
    filtered = filter_deprecated_features(filtered)
    display_names = feature_display_names

    premium_features = account_premium_features
    regular, premium = filtered.partition { |key, _value| premium_features.exclude?(key) }

    [
      sort_and_transform_features(regular, display_names),
      sort_and_transform_features(premium, display_names)
    ]
  end
end
