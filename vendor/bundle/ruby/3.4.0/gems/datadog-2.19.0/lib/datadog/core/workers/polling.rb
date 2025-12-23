# frozen_string_literal: true

require_relative 'async'
require_relative 'interval_loop'

module Datadog
  module Core
    module Workers
      # Adds polling (async looping) behavior to workers
      module Polling
        DEFAULT_SHUTDOWN_TIMEOUT = 1

        def self.included(base)
          base.include(Workers::IntervalLoop)
          base.include(Workers::Async::Thread)
          base.prepend(PrependedMethods)
        end

        # Methods that must be prepended
        module PrependedMethods
          def perform(*args)
            super if enabled?
          end
        end

        def stop(force_stop = false, timeout = DEFAULT_SHUTDOWN_TIMEOUT)
          if running?
            # Attempt graceful stop and wait
            stop_loop
            graceful = join(timeout)

            if !graceful && force_stop
              Datadog.logger.debug do
                "Timeout while waiting for worker to finish gracefully, forcing termination for: #{self}"
              end
              terminate
            else
              graceful
            end
          else
            false
          end
        end

        def enabled?
          return true unless instance_variable_defined?(:@enabled)

          @enabled
        end

        # Allow worker to be started
        def enabled=(value)
          # Coerce to boolean
          @enabled = (value == true)
        end
      end
    end
  end
end
