# frozen_string_literal: true

require_relative '../active_support/notifications/event'

module Datadog
  module Tracing
    module Contrib
      module ActionView
        # Defines basic behavior for an ActionView event.
        module Event
          def self.included(base)
            base.include(ActiveSupport::Notifications::Event)
            base.extend(ClassMethods)
          end

          # Class methods for ActionView events.
          module ClassMethods
            def configuration
              Datadog.configuration.tracing[:action_view]
            end

            def record_exception(span, payload)
              if payload[:exception_object]
                span.set_error(payload[:exception_object])
              elsif payload[:exception]
                # Fallback for ActiveSupport < 5.0
                span.set_error(payload[:exception])
              end
            end
          end
        end
      end
    end
  end
end
