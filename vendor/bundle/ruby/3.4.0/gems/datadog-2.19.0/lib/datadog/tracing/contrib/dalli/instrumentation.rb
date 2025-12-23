# frozen_string_literal: true

require_relative '../../metadata/ext'
require_relative '../analytics'
require_relative 'ext'
require_relative '../ext'
require_relative 'quantize'

module Datadog
  module Tracing
    module Contrib
      module Dalli
        # Instruments every interaction with the memcached server
        module Instrumentation
          def self.included(base)
            base.prepend(InstanceMethods)
          end

          # InstanceMethods - implementing instrumentation
          module InstanceMethods
            def request(op, *args)
              Tracing.trace(Ext::SPAN_COMMAND) do |span|
                span.resource = op.to_s.upcase
                span.service = datadog_configuration[:service_name]
                span.type = Ext::SPAN_TYPE_COMMAND

                if datadog_configuration[:peer_service]
                  span.set_tag(
                    Tracing::Metadata::Ext::TAG_PEER_SERVICE,
                    datadog_configuration[:peer_service]
                  )
                end

                # Tag original global service name if not used
                if span.service != Datadog.configuration.service
                  span.set_tag(Tracing::Contrib::Ext::Metadata::TAG_BASE_SERVICE, Datadog.configuration.service)
                end

                span.set_tag(Tracing::Metadata::Ext::TAG_KIND, Tracing::Metadata::Ext::SpanKind::TAG_CLIENT)

                span.set_tag(Tracing::Metadata::Ext::TAG_COMPONENT, Ext::TAG_COMPONENT)
                span.set_tag(Tracing::Metadata::Ext::TAG_OPERATION, Ext::TAG_OPERATION_COMMAND)
                span.set_tag(Tracing::Metadata::Ext::TAG_PEER_HOSTNAME, hostname)

                # Set analytics sample rate
                if Contrib::Analytics.enabled?(datadog_configuration[:analytics_enabled])
                  Contrib::Analytics.set_sample_rate(span, datadog_configuration[:analytics_sample_rate])
                end

                span.set_tag(Tracing::Metadata::Ext::NET::TAG_TARGET_HOST, hostname)
                span.set_tag(Tracing::Metadata::Ext::NET::TAG_TARGET_PORT, port)

                span.set_tag(Contrib::Ext::DB::TAG_SYSTEM, Ext::TAG_SYSTEM)

                if datadog_configuration[:command_enabled]
                  cmd = Quantize.format_command(op, args)
                  span.set_tag(Ext::TAG_COMMAND, cmd)
                end

                Contrib::SpanAttributeSchema.set_peer_service!(span, Ext::PEER_SERVICE_SOURCES)
                super
              end
            end

            private

            def datadog_configuration
              Datadog.configuration.tracing[:dalli, "#{hostname}:#{port}"]
            end
          end
        end
      end
    end
  end
end
