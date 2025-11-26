module ProductCatalogs
  class RateLimiterService
    LOCK_KEY_PREFIX = 'product_catalog:bulk_operation:lock'.freeze
    VALIDATION_LOCK_KEY_PREFIX = 'product_catalog:validation:lock'.freeze
    RATE_LIMIT_SECONDS = 15
    VALIDATION_LOCK_SECONDS = 60 # Max time for file validation and upload

    class << self
      # Attempts to acquire an atomic lock for file validation
      # This prevents concurrent upload requests from the same account
      # Returns true if lock acquired, false if another validation is in progress
      def acquire_validation_lock(account_id)
        lock_key = build_validation_lock_key(account_id)

        $alfred.with do |redis|
          result = redis.set(lock_key, "VALIDATING:#{Time.current.to_i}", nx: true, ex: VALIDATION_LOCK_SECONDS)

          if result
            Rails.logger.info "RateLimiter: Validation lock acquired for account_id=#{account_id}"
            true
          else
            Rails.logger.warn "RateLimiter: Validation lock denied for account_id=#{account_id} - another validation in progress"
            false
          end
        end
      rescue StandardError => e
        Rails.logger.error "RateLimiter: Redis error acquiring validation lock - #{e.message}"
        true # Allow on Redis failure to prevent blocking
      end

      # Release the validation lock (called after validation completes or fails)
      def release_validation_lock(account_id)
        lock_key = build_validation_lock_key(account_id)

        $alfred.with do |redis|
          redis.del(lock_key)
        end

        Rails.logger.info "RateLimiter: Validation lock released for account_id=#{account_id}"
      rescue StandardError => e
        Rails.logger.error "RateLimiter: Redis error releasing validation lock - #{e.message}"
      end

      # Check if a validation is currently in progress for this account
      def validation_in_progress?(account_id)
        lock_key = build_validation_lock_key(account_id)

        $alfred.with do |redis|
          redis.exists?(lock_key)
        end
      rescue StandardError => e
        Rails.logger.error "RateLimiter: Redis error checking validation lock - #{e.message}"
        false
      end

      # Attempts to acquire an atomic lock for bulk operations (upload/export)
      # Returns true if lock acquired, false if another operation is in progress or rate limited
      def acquire_lock(account_id, operation_type)
        lock_key = build_lock_key(account_id)

        $alfred.with do |redis|
          # Use SET with NX (only set if not exists) and EX (expiry) for atomic operation
          # This ensures only one request can acquire the lock
          result = redis.set(lock_key, build_lock_value(operation_type), nx: true, ex: RATE_LIMIT_SECONDS)

          if result
            Rails.logger.info "RateLimiter: Lock acquired for account_id=#{account_id}, operation=#{operation_type}"
            true
          else
            # Lock exists - check remaining TTL for rate limit info
            ttl = redis.ttl(lock_key)
            current_value = redis.get(lock_key)
            Rails.logger.warn "RateLimiter: Lock denied for account_id=#{account_id}, operation=#{operation_type}. " \
                              "Current lock: #{current_value}, TTL: #{ttl}s"
            false
          end
        end
      rescue StandardError => e
        Rails.logger.error "RateLimiter: Redis error - #{e.message}"
        # On Redis error, allow the operation but log the issue
        # This prevents Redis issues from blocking all operations
        true
      end

      # Gets information about the current lock (if any)
      def lock_info(account_id)
        lock_key = build_lock_key(account_id)

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
        Rails.logger.error "RateLimiter: Redis error getting lock info - #{e.message}"
        nil
      end

      # Manually release a lock (used when operation fails immediately)
      def release_lock(account_id)
        lock_key = build_lock_key(account_id)

        $alfred.with do |redis|
          redis.del(lock_key)
        end

        Rails.logger.info "RateLimiter: Lock released for account_id=#{account_id}"
      rescue StandardError => e
        Rails.logger.error "RateLimiter: Redis error releasing lock - #{e.message}"
      end

      private

      def build_lock_key(account_id)
        "#{LOCK_KEY_PREFIX}:#{account_id}"
      end

      def build_validation_lock_key(account_id)
        "#{VALIDATION_LOCK_KEY_PREFIX}:#{account_id}"
      end

      def build_lock_value(operation_type)
        "#{operation_type}:#{Time.current.to_i}"
      end
    end
  end
end
