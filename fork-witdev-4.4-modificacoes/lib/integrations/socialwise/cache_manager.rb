# frozen_string_literal: true

module Integrations
  module Socialwise
    # Dedicated cache manager for SocialWise operations
    # Uses Redis for cross-process cache sharing to avoid CACHE MISS issues
    class CacheManager
      CACHE_PREFIX = 'socialwise'
      DEFAULT_TTL = 24.hours
      
      # Cache keys
      CHANNEL_TYPE_KEY = 'channel_type'
      PROVIDER_CONFIG_KEY = 'provider_config'
      INBOX_DATA_KEY = 'inbox_data'
      
      class << self
        # Get or set channel type for an inbox
        def channel_type(inbox_id, &block)
          cache_key = build_key(CHANNEL_TYPE_KEY, inbox_id)
          get_or_set(cache_key, DEFAULT_TTL, &block)
        end
        
        # Get or set provider config for an inbox
        def provider_config(inbox_id, &block)
          cache_key = build_key(PROVIDER_CONFIG_KEY, inbox_id)
          get_or_set(cache_key, DEFAULT_TTL, &block)
        end
        
        # Get or set complete inbox data
        def inbox_data(inbox_id, &block)
          cache_key = build_key(INBOX_DATA_KEY, inbox_id)
          get_or_set(cache_key, DEFAULT_TTL, &block)
        end
        
        # Clear all cache for a specific inbox
        def clear_inbox_cache(inbox_id)
          keys_to_delete = [
            build_key(CHANNEL_TYPE_KEY, inbox_id),
            build_key(PROVIDER_CONFIG_KEY, inbox_id),
            build_key(INBOX_DATA_KEY, inbox_id)
          ]
          
          deleted_count = 0
          keys_to_delete.each do |key|
            if redis_client.del(key) > 0
              deleted_count += 1
              Rails.logger.info "[SOCIALWISE_CACHE] Deleted cache key: #{key}"
            end
          end
          
          Rails.logger.info "[SOCIALWISE_CACHE] Cleared #{deleted_count} cache entries for inbox #{inbox_id}"
          deleted_count
        rescue => e
          Rails.logger.error "[SOCIALWISE_CACHE] Error clearing cache for inbox #{inbox_id}: #{e.message}"
          0
        end
        
        # Preload cache for WhatsApp inboxes
        def preload_whatsapp_cache(account_id = nil)
          Rails.logger.info "[SOCIALWISE_CACHE] Preloading WhatsApp inbox cache#{account_id ? " for account #{account_id}" : ""}"
          
          # Find WhatsApp inboxes
          inboxes_query = Inbox.joins(:channel).where(channels: { type: 'Channel::Whatsapp' })
          inboxes_query = inboxes_query.where(account_id: account_id) if account_id
          
          whatsapp_inboxes = inboxes_query.includes(:channel)
          preloaded_count = 0
          
          whatsapp_inboxes.find_each do |inbox|
            # Preload channel type
            channel_type(inbox.id) { inbox.channel_type }
            
            # Preload provider config if available
            if inbox.channel&.provider_config
              provider_config(inbox.id) { inbox.channel.provider_config }
            end
            
            # Preload complete inbox data
            inbox_data(inbox.id) do
              {
                id: inbox.id,
                name: inbox.name,
                channel_type: inbox.channel_type,
                provider_config: inbox.channel&.provider_config || {}
              }
            end
            
            preloaded_count += 1
            Rails.logger.debug "[SOCIALWISE_CACHE] Preloaded cache for WhatsApp inbox #{inbox.id}"
          end
          
          Rails.logger.info "[SOCIALWISE_CACHE] Preloaded cache for #{preloaded_count} WhatsApp inboxes"
          preloaded_count
        rescue => e
          Rails.logger.error "[SOCIALWISE_CACHE] Error preloading WhatsApp cache: #{e.message}"
          0
        end
        
        # Get cache statistics
        def cache_stats
          stats = {}
          
          [CHANNEL_TYPE_KEY, PROVIDER_CONFIG_KEY, INBOX_DATA_KEY].each do |cache_type|
            hits = get_stat_counter("#{cache_type}:hit")
            misses = get_stat_counter("#{cache_type}:miss")
            total = hits + misses
            hit_rate = total > 0 ? ((hits.to_f / total) * 100).round(2) : 0
            
            stats[cache_type] = {
              hits: hits,
              misses: misses,
              total: total,
              hit_rate: hit_rate
            }
          end
          
          stats
        rescue => e
          Rails.logger.error "[SOCIALWISE_CACHE] Error getting cache stats: #{e.message}"
          {}
        end
        
        # Clear all SocialWise cache
        def clear_all_cache
          pattern = "#{redis_namespace}:#{CACHE_PREFIX}:*"
          keys = redis_client.keys(pattern)
          
          return 0 if keys.empty?
          
          deleted_count = redis_client.del(*keys)
          Rails.logger.info "[SOCIALWISE_CACHE] Cleared #{deleted_count} cache entries"
          deleted_count
        rescue => e
          Rails.logger.error "[SOCIALWISE_CACHE] Error clearing all cache: #{e.message}"
          0
        end
        
        # Health check for cache system
        def health_check
          test_key = build_key('health_check', 'test')
          test_value = { timestamp: Time.current.to_i, test: true }
          
          # Test write
          redis_client.setex(test_key, 60, test_value.to_json)
          
          # Test read
          cached_value = redis_client.get(test_key)
          parsed_value = JSON.parse(cached_value) if cached_value
          
          # Test delete
          redis_client.del(test_key)
          
          # Verify the test worked
          if parsed_value && parsed_value['test'] == true
            Rails.logger.info "[SOCIALWISE_CACHE] Health check passed"
            { status: 'healthy', timestamp: Time.current.iso8601 }
          else
            Rails.logger.error "[SOCIALWISE_CACHE] Health check failed - data mismatch"
            { status: 'unhealthy', error: 'data_mismatch', timestamp: Time.current.iso8601 }
          end
        rescue => e
          Rails.logger.error "[SOCIALWISE_CACHE] Health check failed: #{e.message}"
          { status: 'unhealthy', error: e.message, timestamp: Time.current.iso8601 }
        end
        
        private
        
        # Generic get or set method with Redis
        def get_or_set(cache_key, ttl = DEFAULT_TTL, &block)
          # Try to get from cache first
          cached_value = redis_client.get(cache_key)
          
          if cached_value
            increment_stat_counter("#{extract_cache_type(cache_key)}:hit")
            Rails.logger.debug "[SOCIALWISE_CACHE] CACHE HIT for key: #{cache_key}"
            return deserialize_value(cached_value)
          end
          
          # Cache miss - execute block to get value
          increment_stat_counter("#{extract_cache_type(cache_key)}:miss")
          Rails.logger.info "[SOCIALWISE_CACHE] CACHE MISS for key: #{cache_key}, fetching from source"
          
          return nil unless block_given?
          
          value = block.call
          
          # Store in cache if value is not nil
          if value
            serialized_value = serialize_value(value)
            redis_client.setex(cache_key, ttl.to_i, serialized_value)
            Rails.logger.info "[SOCIALWISE_CACHE] Cached value for key: #{cache_key} (TTL: #{ttl.to_i}s)"
          end
          
          value
        rescue => e
          Rails.logger.error "[SOCIALWISE_CACHE] Error in get_or_set for key #{cache_key}: #{e.message}"
          # If cache fails, still try to execute the block
          block_given? ? block.call : nil
        end
        
        # Build cache key with namespace
        def build_key(cache_type, identifier)
          "#{redis_namespace}:#{CACHE_PREFIX}:#{cache_type}:#{identifier}"
        end
        
        # Extract cache type from key for stats
        def extract_cache_type(cache_key)
          parts = cache_key.split(':')
          return 'unknown' if parts.length < 4
          parts[2] # cache_type is the 3rd part (0-indexed)
        end
        
        # Serialize value for Redis storage
        def serialize_value(value)
          case value
          when Hash, Array
            value.to_json
          when String, Integer, Float, TrueClass, FalseClass, NilClass
            value.to_s
          else
            value.to_json
          end
        end
        
        # Deserialize value from Redis
        def deserialize_value(cached_value)
          return nil if cached_value.nil?
          
          # Try to parse as JSON first
          begin
            JSON.parse(cached_value)
          rescue JSON::ParserError
            # If not JSON, return as string
            cached_value
          end
        end
        
        # Get Redis client (using existing Velma connection pool)
        def redis_client
          $velma.with { |conn| conn }
        end
        
        # Get Redis namespace
        def redis_namespace
          'velma' # Using the same namespace as Velma for consistency
        end
        
        # Increment statistics counter
        def increment_stat_counter(stat_key)
          full_key = build_key('stats', stat_key)
          redis_client.incr(full_key)
          redis_client.expire(full_key, 24.hours.to_i) # Auto-expire stats after 24h
        rescue => e
          # Don't let stats errors affect main functionality
          Rails.logger.debug "[SOCIALWISE_CACHE] Stats error for #{stat_key}: #{e.message}"
        end
        
        # Get statistics counter value
        def get_stat_counter(stat_key)
          full_key = build_key('stats', stat_key)
          value = redis_client.get(full_key)
          value ? value.to_i : 0
        rescue => e
          Rails.logger.debug "[SOCIALWISE_CACHE] Error getting stat #{stat_key}: #{e.message}"
          0
        end
      end
    end
  end
end