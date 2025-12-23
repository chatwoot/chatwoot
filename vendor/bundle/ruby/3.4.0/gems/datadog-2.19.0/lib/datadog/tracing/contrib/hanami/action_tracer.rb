# frozen_string_literal: true

require_relative '../../metadata/ext'
require_relative '../analytics'
require_relative 'ext'

module Datadog
  module Tracing
    module Contrib
      module Hanami
        # Hanami Instrumentation for `hanami.action`
        class ActionTracer
          def initialize(app, action)
            @app = app
            @action = action
          end

          def call(env)
            Tracing.trace(
              Ext::SPAN_ACTION,
              resource: @action.to_s,
              service: configuration[:service_name],
              type: Tracing::Metadata::Ext::HTTP::TYPE_INBOUND
            ) do |span_op, trace_op|
              span_op.set_tag(Tracing::Metadata::Ext::TAG_COMPONENT, Ext::TAG_COMPONENT)
              span_op.set_tag(Tracing::Metadata::Ext::TAG_OPERATION, Ext::TAG_OPERATION_ACTION)

              if Contrib::Analytics.enabled?(configuration[:analytics_enabled])
                Contrib::Analytics.set_sample_rate(span_op, configuration[:analytics_sample_rate])
              end

              trace_op.resource = span_op.resource

              @app.call(env)
            end
          end

          private

          def configuration
            Datadog.configuration.tracing[:hanami]
          end
        end
      end
    end
  end
end
