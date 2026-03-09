# frozen_string_literal: true

# Concern to handle SocialWise cache invalidation when inbox data changes
module SocialwiseCacheInvalidation
  extend ActiveSupport::Concern

  included do
    # Clear SocialWise cache when inbox is updated
    after_update :clear_socialwise_cache_if_needed
    after_destroy :clear_socialwise_cache
  end

  private

  def clear_socialwise_cache_if_needed
    # Only clear cache if relevant attributes changed
    relevant_changes = %w[name channel_type]
    
    if (changes.keys & relevant_changes).any?
      Rails.logger.info "[SOCIALWISE_CACHE] Inbox #{id} updated, clearing cache"
      clear_socialwise_cache
    end
  end

  def clear_socialwise_cache
    return unless defined?(Integrations::Socialwise::CacheManager)
    
    begin
      deleted_count = Integrations::Socialwise::CacheManager.clear_inbox_cache(id)
      Rails.logger.info "[SOCIALWISE_CACHE] Cleared #{deleted_count} cache entries for inbox #{id}"
    rescue => e
      Rails.logger.error "[SOCIALWISE_CACHE] Error clearing cache for inbox #{id}: #{e.message}"
    end
  end
end