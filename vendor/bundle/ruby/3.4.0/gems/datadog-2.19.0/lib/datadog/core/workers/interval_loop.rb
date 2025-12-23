# frozen_string_literal: true

module Datadog
  module Core
    module Workers
      # Adds looping behavior to workers, with a sleep
      # interval between each loop.
      module IntervalLoop
        BACK_OFF_RATIO = 1.2
        BACK_OFF_MAX = 5
        BASE_INTERVAL = 1

        # This single shared mutex is used to avoid concurrency issues during the
        # initialization of per-instance lazy-initialized mutexes.
        MUTEX_INIT = Mutex.new

        def self.included(base)
          base.prepend(PrependedMethods)
        end

        # Methods that must be prepended
        module PrependedMethods
          def perform(*args)
            perform_loop do
              @in_iteration = true
              begin
                super(*args)
              ensure
                @in_iteration = false
              end
            end
          end

          def in_iteration?
            defined?(@in_iteration) && @in_iteration
          end
        end

        def stop_loop
          mutex.synchronize do
            return false unless run_loop?

            @run_loop = false
            shutdown.signal
          end

          true
        end

        def work_pending?
          run_loop?
        end

        def run_loop?
          return false unless instance_variable_defined?(:@run_loop)

          @run_loop == true
        end

        def loop_base_interval
          @loop_base_interval ||= BASE_INTERVAL
        end

        def loop_back_off_ratio
          @loop_back_off_ratio ||= BACK_OFF_RATIO
        end

        def loop_back_off_max
          @loop_back_off_max ||= BACK_OFF_MAX
        end

        def loop_wait_time
          @loop_wait_time ||= loop_base_interval
        end

        def loop_wait_time=(value)
          @loop_wait_time = value
        end

        def loop_back_off!
          self.loop_wait_time = [loop_wait_time * BACK_OFF_RATIO, BACK_OFF_MAX].min
        end

        # Should perform_loop just straight into work, or start by waiting?
        #
        # The use case is if we want to report some information (like profiles) from time to time, we may not want to
        # report empty/zero/some residual value immediately when the worker starts.
        def loop_wait_before_first_iteration?
          false
        end

        protected

        attr_writer \
          :loop_back_off_max,
          :loop_back_off_ratio,
          :loop_base_interval

        def mutex
          @mutex || MUTEX_INIT.synchronize { @mutex ||= Mutex.new }
        end

        private

        def perform_loop
          mutex.synchronize do
            @run_loop = true

            shutdown.wait(mutex, loop_wait_time) if loop_wait_before_first_iteration?
          end

          loop do
            if work_pending?
              # There's work to do...
              # Run the task
              yield
            end

            # Wait for an interval, unless shutdown has been signaled.
            mutex.synchronize do
              return unless run_loop? || work_pending?

              shutdown.wait(mutex, loop_wait_time) if run_loop?
            end
          end
        end

        def shutdown
          @shutdown ||= ConditionVariable.new
        end
      end
    end
  end
end
