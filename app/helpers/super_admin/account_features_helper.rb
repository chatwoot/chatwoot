module SuperAdmin::AccountFeaturesHelper
  CATEGORY_ORDER = %w[
    channels
    conversations
    contacts
    ai
    reports
    security
    integrations
    branding
  ].freeze

  CATEGORY_LABELS = {
    'channels' => 'Channels',
    'conversations' => 'Conversations & inbox',
    'contacts' => 'Contacts & CRM',
    'ai' => 'AI / Captain',
    'reports' => 'Reports & search',
    'security' => 'Security & access',
    'integrations' => 'Integrations',
    'branding' => 'Branding & misc'
  }.freeze

  def self.account_features
    YAML.safe_load(Rails.root.join('config/features.yml').read).freeze
  end

  def self.account_premium_features
    account_features.filter { |feature| feature['premium'] }.pluck('name')
  end

  def self.feature_metadata
    account_features.each_with_object({}) do |feature, hash|
      hash[feature['name']] = {
        display_name: feature['display_name'],
        description: feature['description'].to_s,
        category: feature['category'].presence || 'branding',
        premium: feature['premium'] == true
      }
    end
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

  def self.partition_features(features)
    filtered = filter_internal_features(features)
    filtered = filter_deprecated_features(filtered)
    display_names = feature_display_names

    regular, premium = filtered.partition { |key, _value| account_premium_features.exclude?(key) }

    [
      sort_and_transform_features(regular, display_names),
      sort_and_transform_features(premium, display_names)
    ]
  end

  def self.filtered_features(features)
    regular, premium = partition_features(features)
    regular.merge(premium)
  end

  # Ordered category sections for Super Admin Account Features UI.
  # Returns [{ key:, label:, items: [{ key:, display_name:, description:, premium:, enabled: }] }, ...]
  def self.grouped_features(features)
    filtered = filter_deprecated_features(filter_internal_features(features))
    metadata = feature_metadata

    buckets = CATEGORY_ORDER.index_with { |_cat| [] }

    filtered.each do |feature_key, enabled|
      meta = metadata[feature_key] || {}
      category = meta[:category].presence || 'branding'
      category = 'branding' unless buckets.key?(category)

      buckets[category] << {
        key: feature_key,
        display_name: meta[:display_name].presence || feature_key,
        description: meta[:description].to_s,
        premium: meta[:premium] == true,
        enabled: enabled
      }
    end

    buckets.filter_map do |category_key, items|
      next if items.empty?

      {
        key: category_key,
        label: CATEGORY_LABELS[category_key] || category_key.titleize,
        items: items.sort_by { |item| item[:display_name].to_s.downcase }
      }
    end
  end
end
