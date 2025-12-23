# frozen_string_literal: true

require_relative '../../../../tracing'
require_relative '../../../metadata/ext'
require_relative '../distributed/propagation'
require_relative '../../analytics'
require_relative '../ext'
require_relative '../../ext'
require_relative '../formatting'

module Datadog
  module Tracing
    module Contrib
      module GRPC
        module DatadogInterceptor
          # The DatadogInterceptor::Server implements the tracing strategy
          # for gRPC server-side endpoints. When the datadog fields have been
          # added to the gRPC call metadata, this middleware component will
          # extract any client-side tracing information, attempting to associate
          # its tracing context with a parent client-side context
          class Server < Base
            def trace(keywords)
              formatter = GRPC::Formatting::MethodObjectFormatter.new(keywords[:method])

              options = {
                type: Tracing::Metadata::Ext::HTTP::TYPE_INBOUND,
                service: service_name, # TODO: Remove server-side service name configuration
                resource: formatter.resource_name,
                on_error: on_error
              }
              metadata = keywords[:call].metadata

              set_distributed_context!(metadata)

              Tracing.trace(Ext::SPAN_SERVICE, **options) do |span|
                annotate!(span, metadata, formatter)

                begin
                  yield
                rescue StandardError => e
                  code = e.is_a?(::GRPC::BadStatus) ? e.code : ::GRPC::Core::StatusCodes::UNKNOWN
                  span.set_tag(Contrib::Ext::RPC::GRPC::TAG_STATUS_CODE, code)

                  raise
                else
                  span.set_tag(Contrib::Ext::RPC::GRPC::TAG_STATUS_CODE, ::GRPC::Core::StatusCodes::OK)
                end
              end
            end

            private

            def set_distributed_context!(metadata)
              Tracing.continue_trace!(GRPC.extract(metadata))
            rescue StandardError => e
              Datadog.logger.debug(
                "unable to propagate GRPC metadata to context: #{e}"
              )
            end

            def annotate!(span, metadata, formatter)
              metadata.each do |header, value|
                # Datadog propagation headers are considered internal implementation detail.
                next if header.to_s.start_with?(Tracing::Distributed::Datadog::TAGS_PREFIX)

                span.set_tag(header, value)
              end

              # Tag original global service name if not used
              if span.service != Datadog.configuration.service
                span.set_tag(Tracing::Contrib::Ext::Metadata::TAG_BASE_SERVICE, Datadog.configuration.service)
              end

              span.set_tag(Tracing::Metadata::Ext::TAG_KIND, Tracing::Metadata::Ext::SpanKind::TAG_SERVER)
              span.set_tag(Tracing::Metadata::Ext::TAG_COMPONENT, Ext::TAG_COMPONENT)
              span.set_tag(Tracing::Metadata::Ext::TAG_OPERATION, Ext::TAG_OPERATION_SERVICE)

              span.set_tag(Contrib::Ext::RPC::TAG_SYSTEM, Ext::TAG_SYSTEM)
              span.set_tag(Contrib::Ext::RPC::TAG_SERVICE, formatter.legacy_grpc_service)
              span.set_tag(Contrib::Ext::RPC::TAG_METHOD, formatter.legacy_grpc_method)
              span.set_tag(Contrib::Ext::RPC::GRPC::TAG_FULL_METHOD, formatter.grpc_full_method)

              # Set analytics sample rate
              Contrib::Analytics.set_sample_rate(span, analytics_sample_rate) if analytics_enabled?

              # Measure service stats
              Contrib::Analytics.set_measured(span)
            rescue StandardError => e
              Datadog.logger.debug("GRPC server trace failed: #{e}")
            end
          end
        end
      end
    end
  end
end
