# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module Kafka
        # Defines basic behaviors for an event for a consumer group.
        module ConsumerGroupEvent
          def on_start(span, _event, _id, payload)
            super

            span.resource = payload[:group_id]
          end
        end
      end
    end
  end
end
