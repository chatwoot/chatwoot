# frozen_string_literal: true

require_relative 'events/render_partial'
require_relative 'events/render_template'

module Datadog
  module Tracing
    module Contrib
      module ActionView
        # Defines collection of instrumented ActionView events
        module Events
          ALL = [
            Events::RenderPartial,
            Events::RenderTemplate
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
