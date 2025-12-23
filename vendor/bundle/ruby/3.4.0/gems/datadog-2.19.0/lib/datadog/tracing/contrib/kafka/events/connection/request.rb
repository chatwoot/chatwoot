# frozen_string_literal: true

require_relative '../../ext'
require_relative '../../event'

module Datadog
  module Tracing
    module Contrib
      module Kafka
        module Events
          module Connection
            # Defines instrumentation for request.connection.kafka event
            module Request
              include Kafka::Event

              EVENT_NAME = 'request.connection.kafka'

              module_function

              def on_start(span, _event, _id, payload)
                super

                span.resource = payload[:api]

                span.set_tag(Ext::TAG_REQUEST_SIZE, payload[:request_size]) if payload.key?(:request_size)
                span.set_tag(Ext::TAG_RESPONSE_SIZE, payload[:response_size]) if payload.key?(:response_size)
              end

              def span_name
                Ext::SPAN_CONNECTION_REQUEST
              end

              def span_options
                super.merge({ tags: { Tracing::Metadata::Ext::TAG_OPERATION => Ext::TAG_OPERATION_CONNECTION_REQUEST } })
              end
            end
          end
        end
      end
    end
  end
end
