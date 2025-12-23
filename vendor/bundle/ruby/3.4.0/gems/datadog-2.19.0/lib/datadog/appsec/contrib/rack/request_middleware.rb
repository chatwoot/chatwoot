# frozen_string_literal: true

require 'json'

require_relative 'gateway/request'
require_relative 'gateway/response'

require_relative '../../event'
require_relative '../../response'
require_relative '../../api_security'
require_relative '../../security_event'
require_relative '../../instrumentation/gateway'

require_relative '../../../tracing/client_ip'
require_relative '../../../tracing/contrib/rack/header_collection'

module Datadog
  module AppSec
    module Contrib
      module Rack
        WAF_VENDOR_HEADERS_TAGS = %w[
          X-Amzn-Trace-Id
          Cloudfront-Viewer-Ja3-Fingerprint
          Cf-Ray
          X-Cloud-Trace-Context
          X-Appgw-Trace-id
          X-SigSci-RequestID
          X-SigSci-Tags
          Akamai-User-Risk
        ].map(&:downcase).freeze

        # Topmost Rack middleware for AppSec
        # This should be inserted just below Datadog::Tracing::Contrib::Rack::TraceMiddleware
        class RequestMiddleware
          def initialize(app, opt = {})
            @app = app

            @oneshot_tags_sent = false
            @rack_headers = {}
          end

          # rubocop:disable Metrics/MethodLength
          def call(env)
            return @app.call(env) unless Datadog::AppSec.enabled?

            boot = Datadog::Core::Remote::Tie.boot
            Datadog::Core::Remote::Tie::Tracing.tag(boot, active_span)

            security_engine = nil
            ready = false
            ctx = nil

            # For a given request, keep using the first Rack stack scope for
            # nested apps. Don't set `context` local variable so that on popping
            # out of this nested stack we don't finalize the parent's context
            return @app.call(env) if active_context(env)

            Datadog::AppSec.reconfigure_lock do
              security_engine = Datadog::AppSec.security_engine

              if security_engine
                ctx = Datadog::AppSec::Context.activate(
                  Datadog::AppSec::Context.new(active_trace, active_span, security_engine.new_runner)
                )

                env[Datadog::AppSec::Ext::CONTEXT_KEY] = ctx
                ready = true
              end
            end

            # TODO: handle exceptions, except for @app.call

            return @app.call(env) unless ready

            add_appsec_tags(security_engine, ctx)
            add_request_tags(ctx, env)

            http_response = nil
            gateway_request = Gateway::Request.new(env)
            gateway_response = nil

            interrupt_params = catch(::Datadog::AppSec::Ext::INTERRUPT) do
              # TODO: This event should be renamed into `rack.request.start` to
              #       reflect that it's the beginning of the request-cycle
              http_response, _gateway_request = Instrumentation.gateway.push('rack.request', gateway_request) do
                @app.call(env)
              end

              gateway_response = Gateway::Response.new(
                http_response[2], http_response[0], http_response[1], context: ctx
              )

              Instrumentation.gateway.push('rack.request.finish', gateway_request)
              Instrumentation.gateway.push('rack.response', gateway_response)

              nil
            end

            if interrupt_params
              http_response = AppSec::Response.from_interrupt_params(interrupt_params, env['HTTP_ACCEPT']).to_rack
            end

            # NOTE: This is not optimal, but in the current implementation
            #       `gateway_response` is a container to dispatch response event
            #       and in case of interruption it suppose to be `nil`.
            #
            #       `http_response` is a real response object in both cases, but
            #       to save us some computations, we will use already pre-computed
            #       `gateway_response` instead of re-creating it.
            #
            # WARNING: This part will be refactored.
            tmp_response = if interrupt_params
              Gateway::Response.new(http_response[2], http_response[0], http_response[1], context: ctx)
            else
              gateway_response
            end

            if AppSec::APISecurity.enabled? && AppSec::APISecurity.sample_trace?(ctx.trace) &&
                AppSec::APISecurity.sample?(gateway_request.request, tmp_response.response)
              ctx.events.push(
                AppSec::SecurityEvent.new(ctx.extract_schema, trace: ctx.trace, span: ctx.span)
              )
            end

            AppSec::Event.record(ctx, request: gateway_request, response: gateway_response)

            http_response
          ensure
            if ctx
              ctx.export_metrics
              Datadog::AppSec::Context.deactivate
            end
          end
          # rubocop:enable Metrics/MethodLength

          private

          def active_context(env)
            env[Datadog::AppSec::Ext::CONTEXT_KEY]
          end

          def active_trace
            # TODO: factor out tracing availability detection

            return unless defined?(Datadog::Tracing)

            Datadog::Tracing.active_trace
          end

          def active_span
            # TODO: factor out tracing availability detection

            return unless defined?(Datadog::Tracing)

            Datadog::Tracing.active_span
          end

          # standard:disable Metrics/MethodLength
          def add_appsec_tags(security_engine, context)
            span = context.span
            trace = context.trace

            return unless trace && span

            span.set_metric(Datadog::AppSec::Ext::TAG_APPSEC_ENABLED, 1)
            span.set_tag('_dd.runtime_family', 'ruby')
            span.set_tag('_dd.appsec.waf.version', Datadog::AppSec::WAF::VERSION::BASE_STRING)

            if security_engine.ruleset_version
              span.set_tag('_dd.appsec.event_rules.version', security_engine.ruleset_version)

              unless @oneshot_tags_sent
                # Small race condition, but it's inoccuous: worst case the tags
                # are sent a couple of times more than expected
                @oneshot_tags_sent = true

                span.set_tag('_dd.appsec.event_rules.addresses', JSON.dump(security_engine.waf_addresses))

                # Ensure these tags reach the backend
                trace.keep!
                trace.set_tag(
                  Datadog::Tracing::Metadata::Ext::Distributed::TAG_DECISION_MAKER,
                  Datadog::Tracing::Sampling::Ext::Decision::ASM
                )
              end
            end
          end
          # standard:enable Metrics/MethodLength

          # standard:disable Metrics/MethodLength
          def add_request_tags(context, env)
            span = context.span

            return unless span

            # Always add WAF vendors headers
            WAF_VENDOR_HEADERS_TAGS.each do |lowercase_header|
              rack_header = to_rack_header(lowercase_header)
              span.set_tag("http.request.headers.#{lowercase_header}", env[rack_header]) if env[rack_header]
            end

            if span && span.get_tag(Tracing::Metadata::Ext::HTTP::TAG_CLIENT_IP).nil?
              request_header_collection = Datadog::Tracing::Contrib::Rack::Header::RequestHeaderCollection.new(env)

              # always collect client ip, as this is part of AppSec provided functionality
              Datadog::Tracing::ClientIp.set_client_ip_tag!(
                span,
                headers: request_header_collection,
                remote_ip: env['REMOTE_ADDR']
              )
            end
          end
          # standard:enable Metrics/MethodLength

          def to_rack_header(header)
            @rack_headers[header] ||= Datadog::Tracing::Contrib::Rack::Header.to_rack_header(header)
          end
        end
      end
    end
  end
end
