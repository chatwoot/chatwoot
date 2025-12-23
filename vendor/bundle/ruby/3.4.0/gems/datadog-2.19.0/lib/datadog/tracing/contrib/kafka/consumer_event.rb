# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module Kafka
        # Defines basic behaviors for an event for a consumer.
        module ConsumerEvent
          def on_start(span, _event, _id, payload)
            super

            span.set_tag(Ext::TAG_GROUP, payload[:group_id])
            span.set_tag(Tracing::Metadata::Ext::TAG_KIND, Tracing::Metadata::Ext::SpanKind::TAG_CONSUMER)
          end
        end
      end
    end
  end
end
