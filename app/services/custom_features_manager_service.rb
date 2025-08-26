class CustomFeaturesManagerService
  include Singleton

  def initialize
    @logger = CustomFeaturesLogger.instance
    begin
      @custom_features_service = CustomFeaturesService.instance
    rescue StandardError => e
      @logger.error('Failed to initialize CustomFeaturesService', error: e)
      @custom_features_service = nil
    end
  end

  # Get custom features for an account (with validation)
  def get_custom_features(account)
    return [] unless service_available?

    begin
      # Access internal_attributes directly to bypass VALID_KEYS restriction
      stored_features = account.internal_attributes['custom_features'] || []
      return stored_features if stored_features.empty?

      # Validate features against current configuration
      valid_features = stored_features.select do |feature|
        @custom_features_service.feature_exists?(feature)
      end

      # Auto-heal: remove invalid features if any were found
      if valid_features != stored_features
        invalid_features = stored_features - valid_features
        set_custom_features(account, valid_features)

        @logger.info('Auto-cleaned invalid features',
                     account_id: account.id,
                     invalid_features: invalid_features,
                     valid_features: valid_features)
      end

      valid_features
    rescue StandardError => e
      @logger.error('Error getting custom features', account_id: account.id, error: e)
      []
    end
  end

  # Set custom features for an account
  def set_custom_features(account, features)
    return false unless service_available?

    begin
      features = [] if features.nil?
      features = [features] unless features.is_a?(Array)

      # Get available custom features dynamically from configuration
      available_custom_features = @custom_features_service.feature_names

      # Validate and clean up features array
      features = features.compact
                         .map(&:strip)
                         .reject(&:empty?)
                         .select { |f| available_custom_features.include?(f) }
                         .uniq

      # Update internal_attributes directly (bypassing enterprise service)
      new_attrs = account.internal_attributes.dup || {}
      new_attrs['custom_features'] = features
      account.internal_attributes = new_attrs
      account.save
      true
    rescue StandardError => e
      @logger.error('Error setting custom features', account_id: account.id, error: e)
      false
    end
  end

  # Check if a custom feature is enabled for an account
  def custom_feature_enabled?(account, feature_name)
    return false unless service_available?

    begin
      get_custom_features(account).include?(feature_name.to_s)
    rescue StandardError => e
      @logger.error('Error checking custom feature',
                    account_id: account.id,
                    feature_name: feature_name,
                    error: e)
      false
    end
  end

  # Get all available custom features
  def all_custom_features
    return [] unless service_available?

    begin
      @custom_features_service.feature_names
    rescue StandardError => e
      @logger.error('Error getting all custom features', error: e)
      []
    end
  end

  # Get feature display names
  def feature_display_names
    return {} unless service_available?

    begin
      @custom_features_service.display_names_map
    rescue StandardError => e
      @logger.error('Error getting feature display names', error: e)
      {}
    end
  end

  # Get features with metadata
  def features_with_metadata
    return [] unless service_available?

    begin
      @custom_features_service.all_features
    rescue StandardError => e
      @logger.error('Error getting features with metadata', error: e)
      []
    end
  end

  private

  # Check if the custom features service is available and functional
  def service_available?
    return false if @custom_features_service.nil?

    begin
      # Test basic functionality
      @custom_features_service.respond_to?(:feature_names)
    rescue StandardError => e
      @logger.error('CustomFeaturesService is not available', error: e)
      false
    end
  end
end