# frozen_string_literal: true

module Aws
  module Plugins
    module Retries

      # @api private
      # Used in 'standard' and 'adaptive' retry modes.
      class RetryQuota
        INITIAL_RETRY_TOKENS = 500
        RETRY_COST = 5
        NO_RETRY_INCREMENT = 1
        TIMEOUT_RETRY_COST = 10

        def initialize(opts = {})
          @mutex              = Mutex.new
          @max_capacity       = opts.fetch(:max_capacity, INITIAL_RETRY_TOKENS)
          @available_capacity = @max_capacity
        end

        # check if there is sufficient capacity to retry
        # and return it.  If there is insufficient capacity
        # return 0
        # @return [Integer] The amount of capacity checked out
        def checkout_capacity(error_inspector)
          @mutex.synchronize do
            capacity_amount = if error_inspector.networking?
                                TIMEOUT_RETRY_COST
                              else
                                RETRY_COST
                              end

            # unable to acquire capacity
            return 0 if capacity_amount > @available_capacity

            @available_capacity -= capacity_amount
            capacity_amount
          end
        end

        # capacity_amount refers to the amount of capacity requested from
        # the last retry.  It can either be RETRY_COST, TIMEOUT_RETRY_COST,
        # or unset.
        def release(capacity_amount)
          # Implementation note:  The release() method is called for
          # every API call.  In the common case where the request is
          # successful and we're at full capacity, we can avoid locking.
          # We can't exceed max capacity so there's no work we have to do.
          return if @available_capacity == @max_capacity

          @mutex.synchronize do
            @available_capacity += capacity_amount || NO_RETRY_INCREMENT
            @available_capacity = [@available_capacity, @max_capacity].min
          end
        end
      end
    end
  end
end
