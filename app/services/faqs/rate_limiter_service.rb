module Faqs
  class RateLimiterService
    LOCK_KEY_PREFIX = 'faqs:operation:lock'.freeze

    # Rate limit configuration per operation type (in seconds)
    RATE_LIMITS = {
      create: 3         # 3 seconds between creates
    }.freeze

    class << self
      # Attempts to acquire an atomic lock for FAQ operations
      # Returns true if lock acquired, false if rate limited
      def acquire_lock(account_id, operation_type, resource_type = 'item')
        lock_key = build_lock_key(account_id, operation_type, resource_type)
        rate_limit = RATE_LIMITS[operation_type.to_sym] || 5

        $alfred.with do |redis|
          result = redis.set(lock_key, build_lock_value(operation_type), nx: true, ex: rate_limit)

          if result
            Rails.logger.info "FaqRateLimiter: Lock acquired for account_id=#{account_id}, " \
                              "operation=#{operation_type}, resource=#{resource_type}"
            true
          else
            ttl = redis.ttl(lock_key)
            Rails.logger.warn "FaqRateLimiter: Rate limit hit for account_id=#{account_id}, " \
                              "operation=#{operation_type}, resource=#{resource_type}, TTL: #{ttl}s"
            false
          end
        end
      rescue StandardError => e
        Rails.logger.error "FaqRateLimiter: Redis error - #{e.message}"
        # On Redis error, allow the operation to prevent blocking
        true
      end

      # Gets information about the current lock (if any)
      def lock_info(account_id, operation_type, resource_type = 'item')
        lock_key = build_lock_key(account_id, operation_type, resource_type)

        $alfred.with do |redis|
          value = redis.get(lock_key)
          return nil unless value

          ttl = redis.ttl(lock_key)
          operation, timestamp = value.split(':')

          {
            operation_type: operation,
            started_at: Time.at(timestamp.to_i),
            remaining_seconds: [ttl, 0].max
          }
        end
      rescue StandardError => e
        Rails.logger.error "FaqRateLimiter: Redis error getting lock info - #{e.message}"
        nil
      end

      # Get remaining seconds for a specific operation
      def remaining_seconds(account_id, operation_type, resource_type = 'item')
        info = lock_info(account_id, operation_type, resource_type)
        info&.dig(:remaining_seconds) || 0
      end

      # Manually release a lock (used when operation fails immediately)
      def release_lock(account_id, operation_type, resource_type = 'item')
        lock_key = build_lock_key(account_id, operation_type, resource_type)

        $alfred.with do |redis|
          redis.del(lock_key)
        end

        Rails.logger.info "FaqRateLimiter: Lock released for account_id=#{account_id}, " \
                          "operation=#{operation_type}, resource=#{resource_type}"
      rescue StandardError => e
        Rails.logger.error "FaqRateLimiter: Redis error releasing lock - #{e.message}"
      end

      private

      def build_lock_key(account_id, operation_type, resource_type)
        "#{LOCK_KEY_PREFIX}:#{resource_type}:#{operation_type}:#{account_id}"
      end

      def build_lock_value(operation_type)
        "#{operation_type}:#{Time.current.to_i}"
      end
    end
  end
end
