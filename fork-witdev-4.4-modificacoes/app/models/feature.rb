# frozen_string_literal: true

# Feature flag management class
# Provides a clean interface for checking feature flags with account scoping
# Usage: Feature.get(:SOCIALWISE_RICH_DASHBOARD, account_id)
class Feature
  class << self
    # Get feature flag value for a specific account
    # @param flag_name [String, Symbol] The feature flag name
    # @param account_id [Integer, nil] The account ID for scoped flags (optional)
    # @return [Boolean] Whether the feature is enabled
    def get(flag_name, account_id = nil)
      FeatureService.get(flag_name, account_id)
    end

    # Check if feature is enabled globally (installation-wide)
    # @param flag_name [String, Symbol] The feature flag name
    # @return [Boolean] Whether the feature is enabled globally
    def enabled_globally?(flag_name)
      FeatureService.enabled_globally?(flag_name)
    end

    # Check if feature is enabled for a specific account
    # @param flag_name [String, Symbol] The feature flag name
    # @param account_id [Integer] The account ID
    # @return [Boolean] Whether the feature is enabled for the account
    def enabled_for_account?(flag_name, account_id)
      FeatureService.enabled_for_account?(flag_name, account_id)
    end

    # Set account-specific feature flag
    # @param flag_name [String, Symbol] The feature flag name
    # @param account_id [Integer] The account ID
    # @param enabled [Boolean] Whether to enable the feature
    def set_account_flag(flag_name, account_id, enabled)
      FeatureService.set_account_flag(flag_name, account_id, enabled)
    end

    # Remove account-specific feature flag (falls back to global)
    # @param flag_name [String, Symbol] The feature flag name
    # @param account_id [Integer] The account ID
    def remove_account_flag(flag_name, account_id)
      FeatureService.remove_account_flag(flag_name, account_id)
    end

    # Get all accounts with a specific feature flag enabled
    # @param flag_name [String, Symbol] The feature flag name
    # @return [Array<Integer>] Array of account IDs
    def accounts_with_flag(flag_name)
      FeatureService.accounts_with_flag(flag_name)
    end

    # Clear all feature flag caches
    def clear_cache
      FeatureService.clear_cache
    end
  end
end