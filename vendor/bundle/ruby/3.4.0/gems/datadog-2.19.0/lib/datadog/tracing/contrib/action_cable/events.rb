# frozen_string_literal: true

require_relative 'event'
require_relative 'events/broadcast'
require_relative 'events/perform_action'
require_relative 'events/transmit'

module Datadog
  module Tracing
    module Contrib
      module ActionCable
        # Defines collection of instrumented ActionCable events
        module Events
          ALL = [
            Events::Broadcast,
            Events::PerformAction,
            Events::Transmit
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
