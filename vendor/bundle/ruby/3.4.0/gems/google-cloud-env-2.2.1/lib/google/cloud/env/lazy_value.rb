# frozen_string_literal: true

# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "English"

module Google
  module Cloud
    class Env
      ##
      # @private
      #
      # A lazy value box with thread-safe memoization. The first time accessed
      # it will call a given block to compute its value, and will cache that
      # value. Subsequent requests will return the cached value.
      #
      # At most one thread will be allowed to run the computation; if another
      # thread is already in the middle of a computation, any new threads
      # requesting the value will wait until the existing computation is
      # complete, and will use that computation's result rather than kicking
      # off their own computation.
      #
      # If a computation fails with an exception, that exception will also be
      # memoized and reraised on subsequent accesses. A LazyValue can also be
      # configured so subsequent accesses will retry the computation if the
      # previous computation failed. The maximum number of retries is
      # configurable, as is the retry "interval", i.e. the time since the last
      # failure before an access will retry the computation.
      #
      # By default, a computation's memoized value (or final error after
      # retries have been exhausted) is maintained for the lifetime of the Ruby
      # process. However, a computation can also cause its result (or error) to
      # expire after a specified number of seconds, forcing a recomputation on
      # the next access following expiration, by calling
      # {LazyValue.expiring_value} or {LazyValue.raise_expiring_error}.
      #
      # We keep this private for now so we can move it in the future if we need
      # it to be available to other libraries. Currently it should not be used
      # outside of Google::Cloud::Env.
      #
      class LazyValue
        class << self
          ##
          # Creates a special object that can be returned from a computation to
          # indicate that a value expires after the given number of seconds.
          # Any access after the expiration will cause a recomputation.
          #
          # @param lifetime [Numeric] timeout in seconds
          # @param value [Object] the computation result
          #
          def expiring_value lifetime, value
            return value unless lifetime
            ExpiringValue.new lifetime, value
          end

          ##
          # Raise an error that, if it is the final result (i.e. retries have
          # been exhausted), will expire after the given number of seconds. Any
          # access after the expiration will cause a recomputation. If retries
          # will not have been exhausted, expiration is ignored.
          #
          # The error can be specified as an exception object, a string (in
          # which case a RuntimeError will be raised), or a class that descends
          # from Exception (in which case an error of that type will be
          # created, and passed any additional args given).
          #
          # @param lifetime [Numeric] timeout in seconds
          # @param error [String,Exception,Class] the error to raise
          # @param args [Array] any arguments to pass to an error constructor
          #
          def raise_expiring_error lifetime, error, *args
            raise error unless lifetime
            raise ExpiringError, lifetime if error.equal? $ERROR_INFO
            if error.is_a?(Class) && error.ancestors.include?(Exception)
              error = error.new(*args)
            elsif !error.is_a? Exception
              error = RuntimeError.new error.to_s
            end
            begin
              raise error
            rescue error.class
              raise ExpiringError, lifetime
            end
          end
        end

        ##
        # Create a LazyValue.
        #
        # You must pass a block that will be called to compute the value the
        # first time it is accessed. The block should evaluate to the desired
        # value, or raise an exception on error. To specify a value that
        # expires, use {LazyValue.expiring_value}. To raise an exception that
        # expires, use {LazyValue.raise_expiring_error}.
        #
        # You can optionally pass a retry manager, which controls how
        # subsequent accesses might try calling the block again if a compute
        # attempt fails with an exception. A retry manager should either be an
        # instance of {Retries} or an object that duck types it.
        #
        # @param retries [Retries] A retry manager. The default is a retry
        #     manager that tries only once.
        # @param block [Proc] A block that can be called to attempt to compute
        #     the value.
        #
        def initialize retries: nil, &block
          @retries = retries || Retries.new
          @compute_handler = block
          raise ArgumentError, "missing compute handler block" unless block

          # Internally implemented by a state machine, protected by a mutex that
          # ensures state transitions are consistent. The states themselves are
          # implicit in the values of the various instance variables. The
          # following are the major states:
          #
          # 1. **Pending** The value is not known and needs to be computed.
          #     @retries.finished? is false.
          #     @value is nil.
          #     @error is nil if no previous attempt has yet been made to
          #         compute the value, or set to the error that resulted from
          #         the most recent attempt.
          #     @expires_at is set to the monotonic time of the end of the
          #         current retry delay, or nil if the next computation attempt
          #         should happen immediately at the next access.
          #     @computing_thread is nil.
          #     @compute_notify is nil.
          #     @backfill_notify is set if currently backfilling, otherwise nil.
          #     From this state, calling #get will start computation (first
          #     waiting on @backfill_notify if present). Calling #expire! will
          #     have no effect.
          #
          # 2. **Computing** One thread has initiated computation. All other
          #     threads will be blocked (waiting on @compute_notify) until the
          #     computing thread finishes.
          #     @retries.finished? is false.
          #     @value and @error are nil.
          #     @expires_at is set to the monotonic time when computing started.
          #     @computing_thread is set to the thread that is computing.
          #     @compute_notify is set.
          #     @backfill_notify is nil.
          #     From this state, calling #get will cause the thread to wait
          #     (on @compute_notify) for the computing thread to complete.
          #     Calling #expire! will have no effect.
          #     When the computing thread finishes, it will transition either
          #     to Finished if the computation was successful or failed with
          #     no more retries, or back to Pending if computation failed with
          #     at least one retry remaining. It might also set @backfill_notify
          #     if other threads are waiting for completion.
          #
          # 3. **Finished** Computation has succeeded, or has failed and no
          #     more retries remain.
          #     @retries.finished? is true.
          #     either @value or @error is set, and the other is nil, depending
          #         on whether the final state is success or failure. (If both
          #         are nil, it is considered a @value of nil.)
          #     @expires_at is set to the monotonic time of expiration, or nil
          #         if there is no expiration.
          #     @computing_thread is nil.
          #     @compute_notify is nil.
          #     @backfill_notify is set if currently backfilling, otherwise nil.
          #     From this state, calling #get will either return the result or
          #     raise the error. If the current time exceeds @expires_at,
          #     however, it will block on @backfill_notify (if present), and
          #     and then transition to Pending first, and proceed from there.
          #     Calling #expire! will block on @backfill_notify (if present)
          #     and then transition to Pending,
          #
          # @backfill_notify can be set in the Pending or Finished states. This
          # happens when threads that had been waiting on the previous
          # computation are still clearing out and returning their results.
          # Backfill must complete before the next computation attempt can be
          # started from the Pending state, or before an expiration can take
          # place from the Finished state. This prevents an "overlap" situation
          # where a thread that had been waiting for a previous computation,
          # isn't able to return the new result before some other thread starts
          # a new computation or expires the value. Note that it is okay for
          # #set! to be called during backfill; the threads still backfilling
          # will simply return the new value.
          #
          # Note: One might ask if it would be simpler to extend the mutex
          # across the entire computation, having it protect the computation
          # itself, instead of the current approach of having explicit compute
          # and backfill states with notifications and having the mutex protect
          # only the state transition. However, this would not have been able
          # to satisfy the requirement that we be able to detect whether a
          # thread asked for the value during another thread's computation,
          # and thus should "share" in that computation's result even if it's
          # a failure (rather than kicking off a retry). Additionally, we
          # consider it dangerous to have the computation block run inside a
          # mutex, because arbitrary code can run there which might result in
          # deadlocks.
          @mutex = Thread::Mutex.new
          # The evaluated, cached value, which could be nil.
          @value = nil
          # The last error encountered
          @error = nil
          # If non-nil, this is the CLOCK_MONOTONIC time when the current state
          # expires. If the state is finished, this is the time the current
          # value or error expires (while nil means it never expires). If the
          # state is pending, this is the time the wait period before the next
          # retry expires (and nil means there is no delay.) If the state is
          # computing, this is the time when computing started.
          @expires_at = nil
          # Set to a condition variable during computation. Broadcasts when the
          # computation is complete. Any threads wanting to get the value
          # during computation must wait on this first.
          @compute_notify = nil
          # Set to a condition variable during backfill. Broadcasts when the
          # last backfill thread is complete. Any threads wanting to expire the
          # cache or start a new computation during backfill must wait on this
          # first.
          @backfill_notify = nil
          # The number of threads waiting on backfill. Used to determine
          # whether to activate backfill_notify when a computation completes.
          @backfill_count = 0
          # The thread running the current computation. This is tested against
          # new requests to protect against deadlocks where a thread tries to
          # re-enter from its own computation. This is also tested when a
          # computation completes, to ensure that the computation is still
          # relevant (i.e. if #set! interrupts a computation, this is reset to
          # nil).
          @computing_thread = nil
        end

        ##
        # Returns the value. This will either return the value or raise an
        # error indicating failure to compute the value.
        #
        # If the value was previously cached, it will return that cached value,
        # otherwise it will either run the computation to try to determine the
        # value, or wait for another thread that is already running the
        # computation. Thus, this method could block.
        #
        # Any arguments passed will be forwarded to the block if called, but
        # are ignored if a cached value is returned.
        #
        # @return [Object] the value
        # @raise [Exception] if an error happened while computing the value
        #
        def get *extra_args
          @mutex.synchronize do
            # Wait for any backfill to complete, and handle expiration first
            # because it might change the state.
            wait_backfill
            do_expire if should_expire?
            # Main state handling
            if @retries.finished?
              # finished state: return value or error
              return cached_value
            elsif !@compute_notify.nil?
              # computing state: wait for the computing thread to finish then
              # return its result
              wait_compute
              return cached_value
            else
              # pending state
              cur_time = Process.clock_gettime Process::CLOCK_MONOTONIC
              # waiting for the next retry: return current error
              raise @error if @expires_at && cur_time < @expires_at
              # no delay: compute in the current thread
              enter_compute cur_time
              # and continue below
            end
          end

          # Gets here if we just transitioned from pending to compute
          perform_compute extra_args
        end

        ##
        # This method calls {#get} repeatedly until a final result is available
        # or retries have exhausted.
        #
        # Note: this method spins on {#get}, although honoring any retry delay.
        # Thus, it is best to call this only if retries are limited or a retry
        # delay has been configured.
        #
        # @param extra_args [Array] extra arguments to pass to the block
        # @param transient_errors [Array<Class>] An array of exception classes
        #     that will be treated as transient and will allow await to
        #     continue retrying. Exceptions omitted from this list will be
        #     treated as fatal errors and abort the call. Default is
        #     `[StandardError]`.
        # @param max_tries [Integer,nil] The maximum number of times this will
        #     call {#get} before giving up, or nil for a potentially unlimited
        #     number of attempts. Default is 1.
        # @param max_time [Numeric,nil] The maximum time in seconds this will
        #     spend before giving up, or nil (the default) for a potentially
        #     unlimited timeout.
        # @param delay_epsilon [Numeric] An extra delay in seconds to ensure
        #     that retries happen after the retry delay period
        #
        # @return [Object] the value
        # @raise [Exception] if a fatal error happened, or retries have been
        #     exhausted.
        #
        def await *extra_args, transient_errors: nil, max_tries: 1, max_time: nil, delay_epsilon: 0.0001
          transient_errors ||= [StandardError]
          transient_errors = Array transient_errors
          expiry_time = Process.clock_gettime(Process::CLOCK_MONOTONIC) + max_time if max_time
          begin
            get(*extra_args)
          rescue *transient_errors
            # A snapshot of the state. It is possible that another thread has
            # changed this state since we received the error. This is okay
            # because our specification for this method is conservative:
            # whatever we return will have been correct at some point.
            state = internal_state
            # Don't retry unless we're in a state where retries can happen.
            raise if [:failed, :success].include? state[0]
            if max_tries
              # Handle retry countdown
              max_tries -= 1
              raise unless max_tries.positive?
            end
            # Determine the next delay
            delay = determine_await_retry_delay state, expiry_time, delay_epsilon
            # nil means we've exceeded the max time
            raise if delay.nil?
            sleep delay if delay.positive?
            retry
          end
        end

        ##
        # Returns the current low-level state immediately without waiting for
        # computation. Returns a 3-tuple (i.e. a 3-element array) in which the
        # first element is a symbol indicating the overall state, as described
        # below, and the second and third elements are set accordingly.
        #
        # States (the first tuple element) are:
        # * `:pending` - The value has not been computed, or previous
        #   computation attempts have failed but there are retries pending. The
        #   second element will be the most recent error, or nil if no
        #   computation attempt has yet happened. The third element will be the
        #   monotonic time of the end of the current retry delay, or nil if
        #   there will be no delay.
        # * `:computing` - A thread is currently computing the value. The
        #   second element is nil. The third elements is the monotonic time
        #   when the computation started.
        # * `:success` - The computation is finished, and the value is returned
        #   in the second element. The third element may be a numeric value
        #   indicating the expiration monotonic time, or nil for no expiration.
        # * `:failed` - The computation failed finally and no more retries will
        #   be done. The error is returned in the second element. The third
        #   element may be a numeric value indicating the expiration monotonic
        #   time, or nil for no expiration.
        #
        # Future updates may add array elements without warning. Callers should
        # be prepared to ignore additional unexpected elements.
        #
        # @return [Array]
        #
        def internal_state
          @mutex.synchronize do
            if @retries.finished?
              if @error
                [:failed, @error, @expires_at]
              else
                [:success, @value, @expires_at]
              end
            elsif @compute_notify.nil?
              [:pending, @error, @expires_at]
            else
              [:computing, nil, @expires_at]
            end
          end
        end

        ##
        # Force this cache to expire immediately, if computation is complete.
        # Any cached value will be cleared, the retry count is reset, and the
        # next access will call the compute block as if it were the first
        # access. Returns true if this took place. Has no effect and returns
        # false if the computation is not yet complete (i.e. if a thread is
        # currently computing, or if the last attempt failed and retries have
        # not yet been exhausted.)
        #
        # @return [true,false] whether the cache was expired
        #
        def expire!
          @mutex.synchronize do
            wait_backfill
            return false unless @retries.finished?
            do_expire
            true
          end
        end

        ##
        # Set the cache value explicitly and immediately. If a computation is
        # in progress, it is "detached" and its result will no longer be
        # considered.
        #
        # @param value [Object] the value to set
        # @param lifetime [Numeric] the lifetime until expiration in seconds,
        #     or nil (the default) for no expiration.
        # @return [Object] the value
        #
        def set! value, lifetime: nil
          @mutex.synchronize do
            @value = value
            @expires_at = determine_expiry lifetime
            @error = nil
            @retries.finish!
            if @compute_notify.nil?
              enter_backfill
              leave_compute
            end
            value
          end
        end

        private

        ##
        # @private
        # Internal type signaling a value with an expiration
        #
        class ExpiringValue
          def initialize lifetime, value
            @lifetime = lifetime
            @value = value
          end

          attr_reader :lifetime
          attr_reader :value
        end

        ##
        # @private
        # Internal type signaling an error with an expiration.
        #
        class ExpiringError < StandardError
          def initialize lifetime
            super()
            @lifetime = lifetime
          end

          attr_reader :lifetime
        end

        ##
        # @private
        # Perform computation, and transition state on completion.
        # This must be called from outside the mutex.
        # Returns the final value, or raises the final error.
        #
        def perform_compute extra_args
          value = @compute_handler.call(*extra_args)
          @mutex.synchronize do
            handle_success value
          end
        rescue Exception => e # rubocop:disable Lint/RescueException
          @mutex.synchronize do
            handle_failure e
          end
        end

        ##
        # @private
        # Either return the cached value or raise the cached error.
        # This must be called from within the mutex.
        #
        def cached_value
          raise @error if @error
          @value
        end

        ##
        # @private
        # Determine whether we should expire a cached value and compute a new
        # one. Happens in the Finished state if @expires_at is in the past.
        # This must be called from within the mutex.
        #
        def should_expire?
          @retries.finished? && @expires_at && Process.clock_gettime(Process::CLOCK_MONOTONIC) >= @expires_at
        end

        ##
        # @private
        # Reset this cache, transitioning to the Pending state and resetting
        # the retry count.
        # This must be called from within the mutex.
        #
        def do_expire
          @retries.reset!
          @value = @error = @expires_at = nil
        end

        ##
        # @private
        # Wait for backfill to complete if it is in progress, otherwise just
        # return immediately.
        # This must be called from within the mutex.
        #
        def wait_backfill
          @backfill_notify.wait @mutex while @backfill_notify
        end

        ##
        # @private
        # Wait for computation to complete.
        # Also adds the current thread to the backfill list, ensuring that the
        # computing thread will enter the backfill phase on completion. Once
        # computation is done, also checks whether the current thread is the
        # last one to backfill, and if so, turns off backfill mode.
        # This must be called from within the mutex.
        #
        def wait_compute
          if Thread.current.equal? @computing_thread
            raise ThreadError, "deadlock: tried to call LazyValue#get from its own computation"
          end
          @backfill_count += 1
          begin
            @compute_notify.wait @mutex
          ensure
            @backfill_count -= 1
            leave_backfill
          end
        end

        ##
        # @private
        # Initializes compute mode.
        # This must be called from within the mutex.
        #
        def enter_compute cur_time
          @computing_thread = Thread.current
          @compute_notify = Thread::ConditionVariable.new
          @expires_at = cur_time
          @value = @error = nil
        end

        ##
        # @private
        # Finishes compute mode, notifying threads waiting on it.
        # This must be called from within the mutex.
        #
        def leave_compute
          @computing_thread = nil
          @compute_notify.broadcast
          @compute_notify = nil
        end

        ##
        # @private
        # Checks for any threads that need backfill, and if so triggers
        # backfill mode.
        # This must be called from within the mutex.
        #
        def enter_backfill
          return unless @backfill_count.positive?
          @backfill_notify = Thread::ConditionVariable.new
        end

        ##
        # @private
        # Checks whether all threads are done with backfill, and if so notifies
        # threads waiting for backfill to finish.
        # This must be called from within the mutex.
        #
        def leave_backfill
          return unless @backfill_count.zero?
          @backfill_notify.broadcast
          @backfill_notify = nil
        end

        ##
        # @private
        # Sets state to reflect a successful computation (as long as this
        # computation wasn't interrupted by someone calling #set!).
        # Then returns the computed value.
        # This must be called from within the mutex.
        #
        def handle_success value
          expires_at = nil
          if value.is_a? ExpiringValue
            expires_at = determine_expiry value.lifetime
            value = value.value
          end
          if Thread.current.equal? @computing_thread
            @retries.finish!
            @error = nil
            @value = value
            @expires_at = expires_at
            enter_backfill
            leave_compute
          end
          value
        end

        ##
        # @private
        # Sets state to reflect a failed computation (as long as this
        # computation wasn't interrupted by someone calling #set!).
        # Then raises the error.
        # This must be called from within the mutex.
        #
        def handle_failure error
          expires_at = nil
          if error.is_a? ExpiringError
            expires_at = determine_expiry error.lifetime
            error = error.cause
          end
          if Thread.current.equal? @computing_thread
            retry_delay = @retries.next start_time: @expires_at
            @value = nil
            @error = error
            @expires_at =
              if retry_delay.nil?
                # No more retries; use the expiration for the error
                expires_at
              elsif retry_delay.positive?
                determine_expiry retry_delay
              end
            enter_backfill
            leave_compute
          end
          raise error
        end

        ##
        # @private
        # Determines the delay until the next retry during an await
        #
        def determine_await_retry_delay state, expiry_time, delay_epsilon
          cur_time = Process.clock_gettime Process::CLOCK_MONOTONIC
          next_run_time =
            if state[0] == :pending && state[2]
              # Run at end of the current retry delay, plus an epsilon,
              # if in pending state
              state[2] + delay_epsilon
            else
              # Default to run immediately otherwise
              cur_time
            end
          # Signal nil if we're past the max time
          return nil if expiry_time && next_run_time > expiry_time
          # No delay if we're already past the time we want to run
          return 0 if next_run_time < cur_time
          next_run_time - cur_time
        end

        ##
        # @private
        # Determines the expires_at value in monotonic time, given a lifetime.
        #
        def determine_expiry lifetime
          lifetime ? Process.clock_gettime(Process::CLOCK_MONOTONIC) + lifetime : nil
        end
      end

      ##
      # @private
      #
      # This expands on {LazyValue} by providing a lazy key-value dictionary.
      # Each key uses a separate LazyValue; hence multiple keys can be in the
      # process of computation concurrently and independently.
      #
      # We keep this private for now so we can move it in the future if we need
      # it to be available to other libraries. Currently it should not be used
      # outside of Google::Cloud::Env.
      #
      class LazyDict
        ##
        # Create a LazyDict.
        #
        # You must pass a block that will be called to compute the value the
        # first time it is accessed. The block takes the key as an argument and
        # should evaluate to the value for that key, or raise an exception on
        # error. To specify a value that expires, use
        # {LazyValue.expiring_value}. To raise an exception that expires, use
        # {LazyValue.raise_expiring_error}.
        #
        # You can optionally pass a retry manager, which controls how
        # subsequent accesses might try calling the block again if a compute
        # attempt fails with an exception. A retry manager should either be an
        # instance of {Retries} or an object that duck types it.
        #
        # @param retries [Retries,Proc] A retry manager. The default is a retry
        #     manager that tries only once. You can provide either a static
        #     retry manager or a Proc that returns a retry manager.
        # @param block [Proc] A block that can be called to attempt to compute
        #     the value given the key.
        #
        def initialize retries: nil, &block
          @retries = retries
          @compute_handler = block
          @key_values = {}
          @mutex = Thread::Mutex.new
        end

        ##
        # Returns the value for the given key. This will either return the
        # value or raise an error indicating failure to compute the value. If
        # the value was previously cached, it will return that cached value,
        # otherwise it will either run the computation to try to determine the
        # value, or wait for another thread that is already running the
        # computation.
        #
        # Any arguments beyond the initial key argument will be passed to the
        # block if it is called, but are ignored if a cached value is returned.
        #
        # @param key [Object] the key
        # @param extra_args [Array] extra arguments to pass to the block
        # @return [Object] the value
        # @raise [Exception] if an error happened while computing the value
        #
        def get key, *extra_args
          lookup_key(key).get key, *extra_args
        end
        alias [] get

        ##
        # This method calls {#get} repeatedly until a final result is available
        # or retries have exhausted.
        #
        # Note: this method spins on {#get}, although honoring any retry delay.
        # Thus, it is best to call this only if retries are limited or a retry
        # delay has been configured.
        #
        # @param key [Object] the key
        # @param extra_args [Array] extra arguments to pass to the block
        # @param transient_errors [Array<Class>] An array of exception classes
        #     that will be treated as transient and will allow await to
        #     continue retrying. Exceptions omitted from this list will be
        #     treated as fatal errors and abort the call. Default is
        #     `[StandardError]`.
        # @param max_tries [Integer,nil] The maximum number of times this will
        #     call {#get} before giving up, or nil for a potentially unlimited
        #     number of attempts. Default is 1.
        # @param max_time [Numeric,nil] The maximum time in seconds this will
        #     spend before giving up, or nil (the default) for a potentially
        #     unlimited timeout.
        #
        # @return [Object] the value
        # @raise [Exception] if a fatal error happened, or retries have been
        #     exhausted.
        #
        def await key, *extra_args, transient_errors: nil, max_tries: 1, max_time: nil
          lookup_key(key).await key, *extra_args,
                                transient_errors: transient_errors,
                                max_tries: max_tries,
                                max_time: max_time
        end

        ##
        # Returns the current low-level state for the given key. Does not block
        # for computation. See {LazyValue#internal_state} for details.
        #
        # @param key [Object] the key
        # @return [Array] the low-level state
        #
        def internal_state key
          lookup_key(key).internal_state
        end

        ##
        # Force the cache for the given key to expire immediately, if
        # computation is complete.
        #
        # Any cached value will be cleared, the retry count is reset, and the
        # next access will call the compute block as if it were the first
        # access. Returns true if this took place. Has no effect and returns
        # false if the computation is not yet complete (i.e. if a thread is
        # currently computing, or if the last attempt failed and retries have
        # not yet been exhausted.)
        #
        # @param key [Object] the key
        # @return [true,false] whether the cache was expired
        #
        def expire! key
          lookup_key(key).expire!
        end

        ##
        # Force the values for all keys to expire immediately.
        #
        # @return [Array<Object>] A list of keys that were expired. A key is
        #     *not* included if its computation is not yet complete (i.e. if a
        #     thread is currently computing, or if the last attempt failed and
        #     retries have not yet been exhausted.)
        #
        def expire_all!
          all_expired = []
          @mutex.synchronize do
            @key_values.each do |key, value|
              all_expired << key if value.expire!
            end
          end
          all_expired
        end

        ##
        # Set the cache value for the given key explicitly and immediately.
        # If a computation is in progress, it is "detached" and its result will
        # no longer be considered.
        #
        # @param key [Object] the key
        # @param value [Object] the value to set
        # @param lifetime [Numeric] the lifetime until expiration in seconds,
        #     or nil (the default) for no expiration.
        # @return [Object] the value
        #
        def set! key, value, lifetime: nil
          lookup_key(key).set! value, lifetime: lifetime
        end

        private

        ##
        # @private
        # Ensures that exactly one LazyValue exists for the given key, and
        # returns it.
        #
        def lookup_key key
          # Optimization: check for key existence and return quickly without
          # grabbing the mutex. This works because keys are never deleted.
          return @key_values[key] if @key_values.key? key

          @mutex.synchronize do
            if @key_values.key? key
              @key_values[key]
            else
              retries =
                if @retries.respond_to? :reset_dup
                  @retries.reset_dup
                elsif @retries.respond_to? :call
                  @retries.call
                end
              @key_values[key] = LazyValue.new retries: retries, &@compute_handler
            end
          end
        end
      end

      ##
      # @private
      #
      # A simple retry manager with optional delay and backoff. It retries
      # until either a configured maximum number of attempts has been
      # reached, or a configurable total time has elapsed since the first
      # failure.
      #
      # This class is not thread-safe by itself. Access should be protected
      # by an external mutex.
      #
      # We keep this private for now so we can move it in the future if we need
      # it to be available to other libraries. Currently it should not be used
      # outside of Google::Cloud::Env.
      #
      class Retries
        ##
        # Create and initialize a retry manager.
        #
        # @param max_tries [Integer,nil] Maximum number of attempts before we
        #     give up altogether, or nil for no maximum. Default is 1,
        #     indicating one attempt and no retries.
        # @param max_time [Numeric,nil] The maximum amount of time in seconds
        #     until we give up altogether, or nil for no maximum. Default is
        #     nil.
        # @param initial_delay [Numeric] Initial delay between attempts, in
        #     seconds. Default is 0.
        # @param max_delay [Numeric,nil] Maximum delay between attempts, in
        #     seconds, or nil for no max. Default is nil.
        # @param delay_multiplier [Numeric] Multipler applied to the delay
        #     between attempts. Default is 1 for no change.
        # @param delay_adder [Numeric] Value added to the delay between
        #     attempts. Default is 0 for no change.
        # @param delay_includes_time_elapsed [true,false] Whether to deduct any
        #     time already elapsed from the retry delay. Default is false.
        #
        def initialize max_tries: 1,
                       max_time: nil,
                       initial_delay: 0,
                       max_delay: nil,
                       delay_multiplier: 1,
                       delay_adder: 0,
                       delay_includes_time_elapsed: false
          @max_tries = max_tries&.to_i
          raise ArgumentError, "max_tries must be positive" if @max_tries && !@max_tries.positive?
          @max_time = max_time
          raise ArgumentError, "max_time must be positive" if @max_time && !@max_time.positive?
          @initial_delay = initial_delay
          raise ArgumentError, "initial_delay must be nonnegative" if @initial_delay&.negative?
          @max_delay = max_delay
          raise ArgumentError, "max_delay must be nonnegative" if @max_delay&.negative?
          @delay_multiplier = delay_multiplier
          @delay_adder = delay_adder
          @delay_includes_time_elapsed = delay_includes_time_elapsed
          reset!
        end

        ##
        # Create a duplicate in the reset state
        #
        # @return [Retries]
        #
        def reset_dup
          Retries.new max_tries: @max_tries,
                      max_time: @max_time,
                      initial_delay: @initial_delay,
                      max_delay: @max_delay,
                      delay_multiplier: @delay_multiplier,
                      delay_adder: @delay_adder,
                      delay_includes_time_elapsed: @delay_includes_time_elapsed
        end

        ##
        # Returns true if the retry limit has been reached.
        #
        # @return [true,false]
        #
        def finished?
          @current_delay.nil?
        end

        ##
        # Reset to the initial attempt.
        #
        # @return [self]
        #
        def reset!
          @current_delay = :reset
          self
        end

        ##
        # Cause the retry limit to be reached immediately.
        #
        # @return [self]
        #
        def finish!
          @current_delay = nil
          self
        end

        ##
        # Advance to the next attempt.
        #
        # Returns nil if the retry limit has been reached. Otherwise, returns
        # the delay in seconds until the next retry (0 for no delay). Raises an
        # error if the previous call already returned nil.
        #
        # @param start_time [Numeric,nil] Optional start time in monotonic time
        #     units. Used if delay_includes_time_elapsed is set.
        # @return [Numeric,nil]
        #
        def next start_time: nil
          raise "no tries remaining" if finished?
          cur_time = Process.clock_gettime Process::CLOCK_MONOTONIC
          if @current_delay == :reset
            setup_first_retry cur_time
          else
            advance_delay
          end
          advance_retry cur_time
          adjusted_delay start_time, cur_time
        end

        private

        def setup_first_retry cur_time
          @tries_remaining = @max_tries
          @deadline = @max_time ? cur_time + @max_time : nil
          @current_delay = @initial_delay
        end

        def advance_delay
          @current_delay = (@delay_multiplier * @current_delay) + @delay_adder
          @current_delay = @max_delay if @max_delay && @current_delay > @max_delay
        end

        def advance_retry cur_time
          @tries_remaining -= 1 if @tries_remaining
          @current_delay = nil if @tries_remaining&.zero? || (@deadline && cur_time + @current_delay > @deadline)
        end

        def adjusted_delay start_time, cur_time
          delay = @current_delay
          if @delay_includes_time_elapsed && start_time && delay
            delay -= cur_time - start_time
            delay = 0 if delay.negative?
          end
          delay
        end
      end
    end
  end
end
