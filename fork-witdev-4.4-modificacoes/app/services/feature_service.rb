# frozen_string_literal: true

# Feature flag service for account-scoped feature management
# Supports gradual rollout and account-specific feature toggles
class FeatureService
  class << self
    # Get feature flag value for a specific account
    # Falls back to global config if account-specific flag is not set
    # @param flag_name [String, Symbol] The feature flag name
    # @param account_id [Integer] The account ID for scoped flags
    # @return [Boolean] Whether the feature is enabled
    def get(flag_name, account_id = nil)
      flag_name = flag_name.to_s

      # First check account-specific flag if account_id is provided
      if account_id.present?
        account_flag = get_account_flag(flag_name, account_id)
        return account_flag unless account_flag.nil?
      end

      # Fall back to global flag
      get_global_flag(flag_name)
    end

    # Check if feature is enabled globally (installation-wide)
    # @param flag_name [String, Symbol] The feature flag name
    # @return [Boolean] Whether the feature is enabled globally
    def enabled_globally?(flag_name)
      get_global_flag(flag_name.to_s)
    end

    # Check if feature is enabled for a specific account
    # @param flag_name [String, Symbol] The feature flag name
    # @param account_id [Integer] The account ID
    # @return [Boolean] Whether the feature is enabled for the account
    def enabled_for_account?(flag_name, account_id)
      get(flag_name, account_id)
    end

    # Set account-specific feature flag
    # @param flag_name [String, Symbol] The feature flag name
    # @param account_id [Integer] The account ID
    # @param enabled [Boolean] Whether to enable the feature
    def set_account_flag(flag_name, account_id, enabled)
      flag_name = flag_name.to_s
      
      account_flag = AccountFeatureFlag.find_or_initialize_by(
        account_id: account_id,
        flag_name: flag_name
      )
      
      account_flag.enabled = enabled
      account_flag.save!
      
      # Clear cache for this account and flag
      clear_account_cache(flag_name, account_id)
      
      enabled
    end

    # Remove account-specific feature flag (falls back to global)
    # @param flag_name [String, Symbol] The feature flag name
    # @param account_id [Integer] The account ID
    def remove_account_flag(flag_name, account_id)
      flag_name = flag_name.to_s
      
      AccountFeatureFlag.where(
        account_id: account_id,
        flag_name: flag_name
      ).destroy_all
      
      # Clear cache for this account and flag
      clear_account_cache(flag_name, account_id)
    end

    # Get all accounts with a specific feature flag enabled
    # @param flag_name [String, Symbol] The feature flag name
    # @return [Array<Integer>] Array of account IDs
    def accounts_with_flag(flag_name)
      flag_name = flag_name.to_s
      
      AccountFeatureFlag.where(flag_name: flag_name, enabled: true)
                        .pluck(:account_id)
    end

    # Clear all feature flag caches
    def clear_cache
      Rails.cache.delete_matched('feature_flag:*')
      GlobalConfig.clear_cache
    end

    private

    # Get account-specific feature flag value
    # @param flag_name [String] The feature flag name
    # @param account_id [Integer] The account ID
    # @return [Boolean, nil] The flag value or nil if not set
    def get_account_flag(flag_name, account_id)
      cache_key = "feature_flag:account:#{account_id}:#{flag_name}"
      
      Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
        account_flag = AccountFeatureFlag.find_by(
          account_id: account_id,
          flag_name: flag_name
        )
        
        account_flag&.enabled
      end
    end

    # Get global feature flag value
    # @param flag_name [String] The feature flag name
    # @return [Boolean] The global flag value
    def get_global_flag(flag_name)
      global_config = GlobalConfig.get(flag_name)
      value = global_config[flag_name]
      
      # Convert various truthy values to boolean
      case value
      when true, 'true', '1', 1
        true
      when false, 'false', '0', 0, nil, ''
        false
      else
        # For any other value, consider it truthy if present
        value.present?
      end
    end

    # Clear cache for specific account and flag
    # @param flag_name [String] The feature flag name
    # @param account_id [Integer] The account ID
    def clear_account_cache(flag_name, account_id)
      cache_key = "feature_flag:account:#{account_id}:#{flag_name}"
      Rails.cache.delete(cache_key)
    end
  end
end