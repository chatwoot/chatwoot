# frozen_string_literal: true

require_relative '../../context'
require_relative '../analytics'
require_relative '../active_support/notifications/event'
require_relative 'ext'

module Datadog
  module Tracing
    module Contrib
      module ActionCable
        # Defines basic behaviors for an event.
        module Event
          def self.included(base)
            base.include(ActiveSupport::Notifications::Event)
            base.extend(ClassMethods)
          end

          # Class methods for events.
          module ClassMethods
            def span_options
              if configuration[:service_name]
                { service: configuration[:service_name] }
              else
                {}
              end
            end

            def configuration
              Datadog.configuration.tracing[:action_cable]
            end
          end
        end

        # Defines behavior for the first event of a thread execution.
        #
        # This event is not expected to be nested with other event,
        # but to start a fresh tracing context.
        module RootContextEvent
          def self.included(base)
            base.include(ActiveSupport::Notifications::Event)
            base.extend(ClassMethods)
          end

          # Class methods for events.
          module ClassMethods
            include Contrib::ActionCable::Event::ClassMethods

            def subscription(*args, **kwargs)
              super.tap do |subscription|
                subscription.before_trace { ensure_clean_context! }
              end
            end

            private

            # Context objects are thread-bound.
            # If an integration re-uses threads, context from a previous trace
            # could leak into the new trace. This "cleans" current context,
            # preventing such a leak.
            def ensure_clean_context!
              return unless Tracing.active_span

              Tracing.send(:tracer).provider.context = Tracing::Context.new
            end
          end
        end
      end
    end
  end
end
