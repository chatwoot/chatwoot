# frozen_string_literal: true

require 'uri'

require_relative '../../metadata/ext'
require_relative '../analytics'
require_relative '../http_annotation_helper'
require_relative '../utils/quantization/http'
require_relative '../../../core/telemetry/logger'

module Datadog
  module Tracing
    module Contrib
      module HTTP
        # Instrumentation for Net::HTTP
        module Instrumentation
          def self.included(base)
            base.prepend(InstanceMethods)
          end

          # InstanceMethods - implementing instrumentation
          module InstanceMethods
            include Contrib::HttpAnnotationHelper

            # :yield: +response+
            def request(req, body = nil, &block)
              host, = host_and_port(req)
              request_options = datadog_configuration(host)
              client_config = Datadog.configuration_for(self)

              return super(req, body, &block) if Contrib::HTTP.should_skip_tracing?(req)

              Tracing.trace(Ext::SPAN_REQUEST) do |span, trace|
                span.service = service_name(host, request_options, client_config)
                span.type = Tracing::Metadata::Ext::HTTP::TYPE_OUTBOUND
                span.resource = req.method

                if Tracing::Distributed::PropagationPolicy.enabled?(
                  pin_config: client_config,
                  global_config: Datadog.configuration.tracing[:http],
                  trace: trace
                )
                  Contrib::HTTP.inject(trace, req)
                end

                # Add additional request specific tags to the span.
                annotate_span_with_request!(span, req, request_options)

                response = super(req, body, &block)

                # Add additional response specific tags to the span.
                annotate_span_with_response!(span, response, request_options)

                response
              end
            end

            def annotate_span_with_request!(span, request, request_options)
              if request_options[:peer_service]
                span.set_tag(
                  Tracing::Metadata::Ext::TAG_PEER_SERVICE,
                  request_options[:peer_service]
                )
              end

              # Tag original global service name if not used
              if span.service != Datadog.configuration.service
                span.set_tag(Tracing::Contrib::Ext::Metadata::TAG_BASE_SERVICE, Datadog.configuration.service)
              end

              span.set_tag(Tracing::Metadata::Ext::TAG_KIND, Tracing::Metadata::Ext::SpanKind::TAG_CLIENT)

              span.set_tag(Tracing::Metadata::Ext::TAG_COMPONENT, Ext::TAG_COMPONENT)
              span.set_tag(Tracing::Metadata::Ext::TAG_OPERATION, Ext::TAG_OPERATION_REQUEST)
              span.set_tag(
                Tracing::Metadata::Ext::HTTP::TAG_URL,
                Contrib::Utils::Quantization::HTTP.url(request.path, { query: { exclude: :all } })
              )
              span.set_tag(Tracing::Metadata::Ext::HTTP::TAG_METHOD, request.method)

              host, port = host_and_port(request)
              span.set_tag(Tracing::Metadata::Ext::NET::TAG_TARGET_HOST, host)
              span.set_tag(Tracing::Metadata::Ext::NET::TAG_TARGET_PORT, port.to_s)

              span.set_tag(Tracing::Metadata::Ext::TAG_PEER_HOSTNAME, host)

              # Set analytics sample rate
              set_analytics_sample_rate(span, request_options)

              span.set_tags(
                Datadog.configuration.tracing.header_tags.request_tags(request)
              )

              Contrib::SpanAttributeSchema.set_peer_service!(span, Ext::PEER_SERVICE_SOURCES)
            rescue StandardError => e
              Datadog.logger.error("error preparing span from http request: #{e}")
              Datadog::Core::Telemetry::Logger.report(e)
            end

            def annotate_span_with_response!(span, response, request_options)
              return unless response && response.code

              span.set_tag(Tracing::Metadata::Ext::HTTP::TAG_STATUS_CODE, response.code)

              span.set_error(response) if request_options[:error_status_codes].include? response.code.to_i

              span.set_tags(
                Datadog.configuration.tracing.header_tags.response_tags(response)
              )
            rescue StandardError => e
              Datadog.logger.error("error preparing span from http response: #{e}")
              Datadog::Core::Telemetry::Logger.report(e)
            end

            def set_analytics_sample_rate(span, request_options)
              return unless analytics_enabled?(request_options)

              Contrib::Analytics.set_sample_rate(span, analytics_sample_rate(request_options))
            end

            private

            def host_and_port(request)
              if request.respond_to?(:uri) && request.uri
                [request.uri.host, request.uri.port]
              else
                [@address, @port]
              end
            end

            def datadog_configuration(host = :default)
              Datadog.configuration.tracing[:http, host]
            end

            def analytics_enabled?(request_options)
              Contrib::Analytics.enabled?(request_options[:analytics_enabled])
            end

            def analytics_sample_rate(request_options)
              request_options[:analytics_sample_rate]
            end
          end
        end
      end
    end
  end
end
