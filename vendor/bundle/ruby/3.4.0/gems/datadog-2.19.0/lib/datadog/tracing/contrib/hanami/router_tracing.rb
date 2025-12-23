# frozen_string_literal: true

require_relative 'ext'
require_relative '../../metadata/ext'

module Datadog
  module Tracing
    module Contrib
      module Hanami
        # Hanami Instrumentation for `hanami.routing`
        module RouterTracing
          def call(env)
            return super if Tracing.active_span && Tracing.active_span.name == Ext::SPAN_ROUTING

            Tracing.trace(
              Ext::SPAN_ROUTING,
              service: configuration[:service_name],
              type: Tracing::Metadata::Ext::HTTP::TYPE_INBOUND
            ) do |span_op, trace_op|
              begin
                span_op.set_tag(Tracing::Metadata::Ext::TAG_COMPONENT, Ext::TAG_COMPONENT)
                span_op.set_tag(Tracing::Metadata::Ext::TAG_OPERATION, Ext::TAG_OPERATION_ROUTING)

                span_op.resource = nil

                super
              ensure
                span_op.resource ||= if trace_op.resource_override?
                                       trace_op.resource
                                     else
                                       env['REQUEST_METHOD']
                                     end
              end
            end
          end

          def configuration
            Datadog.configuration.tracing[:hanami]
          end
        end
      end
    end
  end
end
