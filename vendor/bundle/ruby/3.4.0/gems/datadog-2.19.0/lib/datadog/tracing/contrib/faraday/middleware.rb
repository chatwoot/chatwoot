# frozen_string_literal: true

require 'faraday'

require_relative '../../metadata/ext'
require_relative '../http'
require_relative '../analytics'
require_relative 'ext'
require_relative '../http_annotation_helper'
require_relative '../../../core/telemetry/logger'

module Datadog
  module Tracing
    module Contrib
      module Faraday
        # Middleware implements a faraday-middleware for datadog instrumentation
        class Middleware < ::Faraday::Middleware
          include Contrib::HttpAnnotationHelper

          def initialize(app, options = {})
            super(app)
            @options = options
          end

          def call(env)
            # Resolve configuration settings to use for this request.
            # Do this once to reduce expensive regex calls.
            request_options = build_request_options!(env)

            Tracing.trace(Ext::SPAN_REQUEST, on_error: request_options[:on_error]) do |span, trace|
              annotate!(span, env, request_options)
              if Tracing::Distributed::PropagationPolicy.enabled?(
                global_config: request_options,
                trace: trace
              )
                propagate!(trace, span, env)
              end
              app.call(env).on_complete { |resp| handle_response(span, resp, request_options) }
            end
          end

          private

          attr_reader :app

          # rubocop:disable Metrics/AbcSize
          def annotate!(span, env, options)
            span.resource = resource_name(env)
            span.service = service_name(env[:url].host, options)
            span.type = Tracing::Metadata::Ext::HTTP::TYPE_OUTBOUND

            if options[:peer_service]
              span.set_tag(
                Tracing::Metadata::Ext::TAG_PEER_SERVICE,
                options[:peer_service]
              )
            end

            # Tag original global service name if not used
            if span.service != Datadog.configuration.service
              span.set_tag(Tracing::Contrib::Ext::Metadata::TAG_BASE_SERVICE, Datadog.configuration.service)
            end

            span.set_tag(Tracing::Metadata::Ext::TAG_KIND, Tracing::Metadata::Ext::SpanKind::TAG_CLIENT)

            span.set_tag(Tracing::Metadata::Ext::TAG_COMPONENT, Ext::TAG_COMPONENT)
            span.set_tag(Tracing::Metadata::Ext::TAG_OPERATION, Ext::TAG_OPERATION_REQUEST)

            span.set_tag(Tracing::Metadata::Ext::TAG_PEER_HOSTNAME, env[:url].host)

            # Set analytics sample rate
            if Contrib::Analytics.enabled?(options[:analytics_enabled])
              Contrib::Analytics.set_sample_rate(span, options[:analytics_sample_rate])
            end

            span.set_tag(Tracing::Metadata::Ext::HTTP::TAG_URL, env[:url].path)
            span.set_tag(Tracing::Metadata::Ext::HTTP::TAG_METHOD, env[:method].to_s.upcase)
            span.set_tag(Tracing::Metadata::Ext::NET::TAG_TARGET_HOST, env[:url].host)
            span.set_tag(Tracing::Metadata::Ext::NET::TAG_TARGET_PORT, env[:url].port)
            span.set_tags(
              Datadog.configuration.tracing.header_tags.request_tags(env[:request_headers])
            )

            Contrib::SpanAttributeSchema.set_peer_service!(span, Ext::PEER_SERVICE_SOURCES)
          rescue StandardError => e
            Datadog.logger.error(e.message)
            Datadog::Core::Telemetry::Logger.report(e)
          end
          # rubocop:enable Metrics/AbcSize

          def handle_response(span, env, options)
            span.set_error(["Error #{env[:status]}", env[:body]]) if options[:error_status_codes].include? env[:status]

            span.set_tag(Tracing::Metadata::Ext::HTTP::TAG_STATUS_CODE, env[:status])

            span.set_tags(
              Datadog.configuration.tracing.header_tags.response_tags(env[:response_headers])
            )
          rescue StandardError => e
            Datadog.logger.error(e.message)
            Datadog::Core::Telemetry::Logger.report(e)
          end

          def propagate!(trace, span, env)
            Contrib::HTTP.inject(trace, env[:request_headers])
          end

          def resource_name(env)
            env[:method].to_s.upcase
          end

          def build_request_options!(env)
            datadog_configuration
              .options_hash # integration level settings
              .merge(datadog_configuration(env[:url].host).options_hash) # per-host override
              .merge(@options) # middleware instance override
          end

          def datadog_configuration(host = :default)
            Datadog.configuration.tracing[:faraday, host]
          end
        end
      end
    end
  end
end
