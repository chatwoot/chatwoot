module ApplicationHelper
  # Keep the full locale catalog in LANGUAGES_CONFIG, but expose only these in UI selectors.
  VISIBLE_LOCALE_CODES = %w[ru kk en].freeze

  def available_locales_with_name
    locales_by_code = LANGUAGES_CONFIG.each_with_object({}) do |(_key, val), memo|
      memo[val[:iso_639_1_code]] = val.slice(:name, :iso_639_1_code)
    end

    VISIBLE_LOCALE_CODES.filter_map { |locale_code| locales_by_code[locale_code] }
  end

  def feature_help_urls
    features = YAML.safe_load(Rails.root.join('config/features.yml').read).freeze
    features.each_with_object({}) do |feature, hash|
      hash[feature['name']] = feature['help_url'] if feature['help_url']
    end
  end
end
