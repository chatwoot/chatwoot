class CustomFeaturesService
  CACHE_KEY = 'custom_features_config'
  CACHE_TTL = 1.hour
  
  def self.all_features
    Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_TTL) do
      load_features_from_file
    end
  end
  
  def self.feature_names
    all_features.pluck('name')
  end
  
  def self.find_feature(name)
    features_by_name[name.to_s]
  end
  
  def self.feature_exists?(name)
    feature_names.include?(name.to_s)
  end
  
  def self.features_by_category(category)
    all_features.select { |feature| feature['category'] == category.to_s }
  end
  
  def self.features_by_tier(tier)
    all_features.select { |feature| feature['tier'] == tier.to_s }
  end
  
  def self.reload!
    Rails.cache.delete(CACHE_KEY)
    @features_by_name = nil
  end
  
  def self.display_names_map
    all_features.each_with_object({}) do |feature, hash|
      hash[feature['display_name']] = feature['name']
    end
  end
  
  def self.js_constants
    return {} if all_features.empty?

    all_features.each_with_object({}) do |feature, constants|
      constant_name = feature['name'].upcase
      constants[constant_name] = feature['name']
    end
  end
  
  def self.js_constants_string
    JSON.pretty_generate(js_constants)
  end
  
  def self.metadata_json
    all_features.to_json
  end
  
  private
  
  def self.load_features_from_file
    config_path = Rails.root.join('config/custom_features.yml')
    return [] unless File.exist?(config_path)
    
    features = YAML.safe_load(File.read(config_path)) || []
    validate_features!(features)
    features
  rescue StandardError => e
    Rails.logger.error("Failed to load custom features: #{e.message}")
    []
  end
  
  def self.features_by_name
    @features_by_name ||= all_features.index_by { |feature| feature['name'] }
  end
  
  def self.validate_features!(features)
    return if features.empty?

    required_keys = %w[name display_name]
    errors = []

    # Validate each feature structure
    features.each_with_index do |feature, index|
      unless feature.is_a?(Hash)
        errors << "Feature at index #{index} must be a hash/object, got #{feature.class}"
        next
      end

      # Check required keys
      required_keys.each do |key|
        unless feature.key?(key) && feature[key].present?
          feature_id = feature['name'] || "feature at index #{index}"
          errors << "Feature '#{feature_id}' is missing required key: #{key}"
        end
      end

      # Validate name format (should be snake_case, no spaces or special chars except underscore)
      if feature['name'].present? && feature['name'] !~ /\A[a-z][a-z0-9_]*\z/
        errors << "Feature name '#{feature['name']}' must be lowercase letters, numbers, and underscores only"
      end
    end

    # Check for duplicate names
    names = features.filter_map { |f| f['name'] if f.is_a?(Hash) && f['name'].present? }
    duplicates = names.select { |name| names.count(name) > 1 }.uniq
    errors << "Duplicate feature names found: #{duplicates.join(', ')}" if duplicates.any?

    if errors.any?
      error_message = "Custom features configuration validation failed:\n" + errors.map { |e| "  - #{e}" }.join("\n")
      Rails.logger.error('Configuration validation failed', validation_errors: errors)
      raise error_message
    end

    Rails.logger.debug('Configuration validation passed', feature_count: names.count)
  end
end