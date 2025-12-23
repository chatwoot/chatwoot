# frozen_string_literal: true

require_relative 'events/render'
require_relative 'events/serialize'

module Datadog
  module Tracing
    module Contrib
      module ActiveModelSerializers
        # Defines collection of instrumented ActiveModelSerializers events
        module Events
          ALL = [
            Events::Render,
            Events::Serialize
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
