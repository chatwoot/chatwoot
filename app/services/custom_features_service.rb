class CustomFeaturesService
  include Singleton

  def initialize
    @features_cache = nil
    @features_by_name_cache = nil
    @file_listener = nil
    @cache_mutex = Mutex.new
    @load_attempts = 0
    @max_load_attempts = 3
    @last_successful_config = nil
    @logger = CustomFeaturesLogger.instance
  end

  # Get all custom features as an array (thread-safe)
  def all_features
    @cache_mutex.synchronize do
      load_features unless @features_cache
      @features_cache
    end
  end

  # Get all custom feature names as an array
  def feature_names
    all_features.pluck('name')
  end

  # Get a specific feature by name
  def find_feature(name)
    features_by_name[name.to_s]
  end

  # Check if a feature exists
  def feature_exists?(name)
    feature_names.include?(name.to_s)
  end

  # Get features by category
  def features_by_category(category)
    all_features.select { |feature| feature['category'] == category.to_s }
  end

  # Get features by tier
  def features_by_tier(tier)
    all_features.select { |feature| feature['tier'] == tier.to_s }
  end

  # Clear the cache (useful for testing or config reloads)
  def clear_cache!
    @cache_mutex.synchronize do
      @features_cache = nil
      @features_by_name_cache = nil
    end
  end

  # Get feature display names mapped to internal names (for UI dropdowns)
  def display_names_map
    all_features.each_with_object({}) do |feature, hash|
      hash[feature['display_name']] = feature['name']
    end
  end

  # Generate JavaScript constants object for frontend
  def js_constants
    return {} if all_features.empty?

    all_features.each_with_object({}) do |feature, constants|
      constant_name = feature['name'].upcase
      constants[constant_name] = feature['name']
    end
  end

  # Generate JavaScript constants as formatted string (for embedding in HTML)
  def js_constants_string
    JSON.pretty_generate(js_constants)
  end

  # Get features metadata as JSON string (for embedding in HTML)
  def metadata_json
    all_features.to_json
  end

  # Check if configuration file has changed
  def file_changed?
    config_path = Rails.root.join('config/custom_features.yml')
    return false unless File.exist?(config_path)
    
    current_timestamp = File.mtime(config_path).to_i.to_s
    cached_timestamp = Redis::Alfred.get(Redis::RedisKeys::CUSTOM_FEATURES_FILE_TIMESTAMP)
    
    current_timestamp != cached_timestamp
  rescue StandardError => e
    @logger.warn('Failed to check file change via Redis, assuming no change', error: e)
    false
  end

  # Update file timestamp in cache
  def update_file_timestamp
    config_path = Rails.root.join('config/custom_features.yml')
    return unless File.exist?(config_path)
    
    timestamp = File.mtime(config_path).to_i.to_s
    Redis::Alfred.set(Redis::RedisKeys::CUSTOM_FEATURES_FILE_TIMESTAMP, timestamp)
    @logger.debug('Updated file timestamp in cache', timestamp: timestamp)
  rescue StandardError => e
    @logger.warn('Failed to update file timestamp in Redis cache', error: e)
  end

  # Setup file system watching for live config reloading
  def setup_file_watching(enabled: true)
    return unless enabled
    return if @file_listener&.processing?

    begin
      require 'listen'

      config_dir = Rails.root.join('config')
      @file_listener = Listen.to(config_dir, only: /custom_features\.yml$/) do |modified, added, removed|
        if modified.any? || added.any? || removed.any?
          @logger.config_change('file_change_detected')
          reload_configuration!
        end
      end

      @file_listener.start
      @logger.info('File watching enabled', file_watching: true)
    rescue LoadError => e
      @logger.warn('Listen gem not available, file watching disabled', error: e)
    rescue StandardError => e
      @logger.error('Failed to setup file watching', error: e)
    end
  end

  # Stop file watching (useful for testing or shutdown)
  def stop_file_watching
    return unless @file_listener

    @file_listener.stop
    @file_listener = nil
    @logger.info('File watching stopped', file_watching: false)
  end

  # Reload configuration (thread-safe)
  def reload_configuration!
    @cache_mutex.synchronize do
      previous_features = @features_cache&.map { |f| f['name'] } || []

      clear_cache!
      new_features = all_features.map { |f| f['name'] }

      # Log changes for visibility
      added = new_features - previous_features
      removed = previous_features - new_features

      @logger.config_change('reloaded', { added: added, removed: removed, total_features: new_features.count }) if added.any? || removed.any?
      @logger.config_change('reloaded', { total_features: new_features.count }) if added.empty? && removed.empty?
    end
  end

  private

  def load_features
    # Check if file has changed since last load
    if file_changed?
      @logger.info('Configuration file changed, reloading...')
      # Clear cache directly without acquiring mutex (we're already synchronized)
      @features_cache = nil
      @features_by_name_cache = nil
    end
    
    config_path = Rails.root.join('config/custom_features.yml')
    @load_attempts += 1

    unless File.exist?(config_path)
      @logger.warn('Configuration file missing', config_path: config_path.to_s)
      @features_cache = []
      @load_attempts = 0 # Reset attempts for missing file
      return
    end

    unless File.readable?(config_path)
      handle_load_failure("Custom features configuration file exists but is not readable: #{config_path}")
      return
    end

    begin
      raw_content = YAML.load_file(config_path)

      if raw_content.nil?
        @logger.warn('Configuration file is empty', config_path: config_path.to_s)
        @features_cache = []
        @load_attempts = 0 # Reset attempts for empty file
        return
      end

      unless raw_content.is_a?(Array)
        handle_load_failure("Custom features configuration must be an array, got #{raw_content.class}: #{config_path}")
        return
      end

      @features_cache = raw_content
      validate_features!

      # Update file timestamp in cache
      update_file_timestamp

      # Success! Reset attempts and save backup
      @load_attempts = 0
      @last_successful_config = @features_cache.deep_dup
      @logger.info('Successfully loaded configuration',
                   feature_count: @features_cache.count,
                   config_path: config_path.to_s)

    rescue Psych::SyntaxError => e
      handle_load_failure("Invalid YAML syntax in custom features configuration: #{e.message}. Please check the syntax in #{config_path}")
    rescue StandardError => e
      handle_load_failure("Unexpected error loading custom features configuration: #{e.message}. Configuration file: #{config_path}")
    end
  end

  def handle_load_failure(error_message)
    @logger.error(error_message)

    if @load_attempts >= @max_load_attempts
      if @last_successful_config
        @logger.warn('Maximum load attempts reached, using backup',
                     attempts: @max_load_attempts,
                     backup_feature_count: @last_successful_config.size)
        @features_cache = @last_successful_config.deep_dup
      else
        @logger.warn('Maximum load attempts reached, no backup available',
                     attempts: @max_load_attempts)
        @features_cache = []
      end
      @load_attempts = 0 # Reset for next time
    else
      @logger.info('Load attempt failed, will retry',
                   attempt: @load_attempts,
                   max_attempts: @max_load_attempts)
      @features_cache ||= [] # Keep previous cache if available
    end
  end

  def features_by_name
    return @features_by_name_cache if @features_by_name_cache

    @features_by_name_cache = all_features.index_by do |feature|
      feature['name']
    end
  end

  def validate_features!
    return if @features_cache.empty?

    required_keys = %w[name display_name]
    errors = []

    # Validate each feature structure
    @features_cache.each_with_index do |feature, index|
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
    names = @features_cache.filter_map { |f| f['name'] if f.is_a?(Hash) && f['name'].present? }
    duplicates = names.select { |name| names.count(name) > 1 }.uniq
    errors << "Duplicate feature names found: #{duplicates.join(', ')}" if duplicates.any?

    if errors.any?
      error_message = "Custom features configuration validation failed:\n" + errors.map { |e| "  - #{e}" }.join("\n")
      @logger.error('Configuration validation failed', validation_errors: errors)
      raise error_message
    end

    @logger.debug('Configuration validation passed', feature_count: names.count)
  end
end