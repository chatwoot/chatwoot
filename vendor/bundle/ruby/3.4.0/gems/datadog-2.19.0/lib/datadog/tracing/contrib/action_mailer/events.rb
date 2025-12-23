# frozen_string_literal: true

require_relative 'events/process'
require_relative 'events/deliver'

module Datadog
  module Tracing
    module Contrib
      module ActionMailer
        # Defines collection of instrumented ActionMailer events
        module Events
          ALL = [
            Events::Process,
            Events::Deliver
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
