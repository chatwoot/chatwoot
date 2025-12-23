# frozen_string_literal: true

require_relative 'events/discard'
require_relative 'events/enqueue'
require_relative 'events/enqueue_at'
require_relative 'events/enqueue_retry'
require_relative 'events/perform'
require_relative 'events/retry_stopped'

module Datadog
  module Tracing
    module Contrib
      module ActiveJob
        # Defines collection of instrumented ActiveJob events
        module Events
          ALL = [
            Events::Discard,
            Events::Enqueue,
            Events::EnqueueAt,
            Events::EnqueueRetry,
            Events::Perform,
            Events::RetryStopped,
          ].freeze

          module_function

          def all
            self::ALL
          end

          def subscriptions
            all.collect(&:subscriptions).collect(&:to_a).flatten
          end

          def subscribe!
            all.each(&:subscribe!)
          end
        end
      end
    end
  end
end
