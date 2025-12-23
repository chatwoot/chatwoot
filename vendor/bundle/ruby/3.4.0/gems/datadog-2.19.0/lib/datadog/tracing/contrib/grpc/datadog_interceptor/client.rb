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
          # The DatadogInterceptor::Client implements the tracing strategy
          # for gRPC client-side endpoints. This middleware component will
          # inject trace context information into gRPC metadata prior to
          # sending the request to the server.
          class Client < Base
            def trace(keywords)
              formatter = GRPC::Formatting::FullMethodStringFormatter.new(keywords[:method])

              options = {
                type: Tracing::Metadata::Ext::HTTP::TYPE_OUTBOUND,
                service: service_name, # Maintain client-side service name configuration
                resource: formatter.resource_name,
                on_error: on_error
              }

              Tracing.trace(Ext::SPAN_CLIENT, **options) do |span, trace|
                annotate!(trace, span, keywords, formatter)

                begin
                  result = yield
                rescue StandardError => e
                  code = e.is_a?(::GRPC::BadStatus) ? e.code : ::GRPC::Core::StatusCodes::UNKNOWN
                  span.set_tag(Contrib::Ext::RPC::GRPC::TAG_STATUS_CODE, code)

                  raise
                end
                span.set_tag(Contrib::Ext::RPC::GRPC::TAG_STATUS_CODE, ::GRPC::Core::StatusCodes::OK)
                result
              end
            end

            private

            def annotate!(trace, span, keywords, formatter)
              metadata = keywords[:metadata] || {}
              call = keywords[:call]

              span.set_tags(metadata)

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
              span.set_tag(Tracing::Metadata::Ext::TAG_OPERATION, Ext::TAG_OPERATION_CLIENT)

              span.set_tag(Contrib::Ext::RPC::TAG_SYSTEM, Ext::TAG_SYSTEM)
              span.set_tag(Contrib::Ext::RPC::GRPC::TAG_FULL_METHOD, formatter.grpc_full_method)
              span.set_tag(Contrib::Ext::RPC::TAG_SERVICE, formatter.rpc_service)

              host, _port = find_host_port(call)
              span.set_tag(Tracing::Metadata::Ext::TAG_PEER_HOSTNAME, host) if host

              deadline = find_deadline(call)
              span.set_tag(Ext::TAG_CLIENT_DEADLINE, deadline) if deadline

              # Set analytics sample rate
              Contrib::Analytics.set_sample_rate(span, analytics_sample_rate) if analytics_enabled?

              if Tracing::Distributed::PropagationPolicy.enabled?(
                pin_config: Datadog.configuration_for(self),
                global_config: datadog_configuration,
                trace: trace
              )
                GRPC.inject(trace, metadata)
              end
              Contrib::SpanAttributeSchema.set_peer_service!(span, Ext::PEER_SERVICE_SOURCES)
            rescue StandardError => e
              Datadog.logger.debug("GRPC client trace failed: #{e}")
            end

            def find_deadline(call)
              return unless call.respond_to?(:deadline) && call.deadline.is_a?(Time)

              call.deadline.utc.iso8601(3)
            end

            def find_host_port(call)
              return unless call

              peer_address = if call.respond_to?(:peer)
                               call.peer
                             else
                               # call is a "view" class with restricted method visibility.
                               # We reach into it to find our data source anyway.
                               call.instance_variable_get(:@wrapped).peer
                             end

              Core::Utils.extract_host_port(peer_address)
            rescue => e
              Datadog.logger.debug { "Could not parse host:port from #{call}: #{e}" }
              nil
            end
          end
        end
      end
    end
  end
end
