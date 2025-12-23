require "sentry/rails/tracing/abstract_subscriber"

module Sentry
  module Rails
    module Tracing
      class ActionViewSubscriber < AbstractSubscriber
        EVENT_NAMES = ["render_template.action_view"].freeze
        SPAN_PREFIX = "template.".freeze
        SPAN_ORIGIN = "auto.template.rails".freeze

        def self.subscribe!
          subscribe_to_event(EVENT_NAMES) do |event_name, duration, payload|
            record_on_current_span(
              op: SPAN_PREFIX + event_name,
              origin: SPAN_ORIGIN,
              start_timestamp: payload[START_TIMESTAMP_NAME],
              description: payload[:identifier],
              duration: duration
            )
          end
        end
      end
    end
  end
end
