# frozen_string_literal: true

require_relative 'events/cache'

module Datadog
  module Tracing
    module Contrib
      module ActiveSupport
        module Cache
          # Defines collection of instrumented ActiveSupport events
          module Events
            ALL = [
              Events::Cache,
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
end
