# frozen_string_literal: true

require 'date'

require_relative '../../../core/environment/variable_helpers'
require_relative '../../../core/remote/tie/tracing'
require_relative '../../client_ip'
require_relative '../../metadata/ext'
require_relative '../http'
require_relative '../analytics'
require_relative '../utils/quantization/http'
require_relative 'ext'
require_relative 'header_collection'
require_relative 'header_tagging'
require_relative 'request_queue'
require_relative 'trace_proxy_middleware'

module Datadog
  module Tracing
    module Contrib
      # Rack module includes middlewares that are required to trace any framework
      # and application built on top of Rack.
      module Rack
        # TraceMiddleware ensures that the Rack Request is properly traced
        # from the beginning to the end. The middleware adds the request span
        # in the Rack environment so that it can be retrieved by the underlying
        # application. If request tags are not set by the app, they will be set using
        # information available at the Rack level.
        class TraceMiddleware
          def initialize(app)
            @app = app
          end

          def call(env)
            # Find out if this is rack within rack
            previous_request_span = env[Ext::RACK_ENV_REQUEST_SPAN]

            return @app.call(env) if previous_request_span

            boot = Datadog::Core::Remote::Tie.boot

            # Extract distributed tracing context before creating any spans,
            # so that all spans will be added to the distributed trace.
            if configuration[:distributed_tracing]
              trace_digest = Contrib::HTTP.extract(env)
              Tracing.continue_trace!(trace_digest) if trace_digest
            end

            TraceProxyMiddleware.call(env, configuration) do
              trace_options = { type: Tracing::Metadata::Ext::HTTP::TYPE_INBOUND }
              trace_options[:service] = configuration[:service_name] if configuration[:service_name]

              # start a new request span and attach it to the current Rack environment;
              # we must ensure that the span `resource` is set later
              request_span = Tracing.trace(Ext::SPAN_REQUEST, **trace_options)
              request_span.resource = nil

              # When tracing and distributed tracing are both disabled, `.active_trace` will be `nil`,
              # Return a null object to continue operation
              request_trace = Tracing.active_trace || TraceOperation.new
              env[Ext::RACK_ENV_REQUEST_SPAN] = request_span

              Datadog::Core::Remote::Tie::Tracing.tag(boot, request_span)

              # Copy the original env, before the rest of the stack executes.
              # Values may change; we want values before that happens.
              original_env = env.dup

              # call the rest of the stack
              status, headers, response = @app.call(env)

              [status, headers, response]

            # Here we really want to catch *any* exception, not only StandardError,
            # as we really have no clue of what is in the block,
            # and it is user code which should be executed no matter what.
            # It's not a problem since we re-raise it afterwards so for example a
            # SignalException::Interrupt would still bubble up.
            rescue Exception => e # rubocop:disable Lint/RescueException
              # catch exceptions that may be raised in the middleware chain
              # Note: if a middleware catches an Exception without re raising,
              # the Exception cannot be recorded here.
              request_span.set_error(e) unless request_span.nil?
              raise e
            ensure
              env[Ext::RACK_ENV_REQUEST_SPAN] = previous_request_span if previous_request_span

              if request_span
                # Rack is a really low level interface and it doesn't provide any
                # advanced functionality like routers. Because of that, we assume that
                # the underlying framework or application has more knowledge about
                # the result for this request; `resource` and `tags` are expected to
                # be set in another level but if they're missing, reasonable defaults
                # are used.
                set_request_tags!(request_trace, request_span, env, status, headers, response, original_env || env)

                # ensure the request_span is finished and the context reset;
                # this assumes that the Rack middleware creates a root span
                request_span.finish
              end
            end
          end

          # rubocop:disable Metrics/AbcSize
          # rubocop:disable Metrics/CyclomaticComplexity
          # rubocop:disable Metrics/PerceivedComplexity
          # rubocop:disable Metrics/MethodLength
          def set_request_tags!(trace, request_span, env, status, headers, response, original_env)
            request_header_collection = Header::RequestHeaderCollection.new(env)

            # Since it could be mutated, it would be more accurate to fetch from the original env,
            # e.g. ActionDispatch::ShowExceptions middleware with Rails exceptions_app configuration
            original_request_method = original_env['REQUEST_METHOD']

            # request_headers is subject to filtering and configuration so we
            # get the user agent separately
            user_agent = parse_user_agent_header(request_header_collection)

            # The priority
            # 1. User overrides span.resource
            # 2. Configuration
            # 3. Nested App override trace.resource
            # 4. Fallback with verb + status, eq `GET 200`
            request_span.resource ||=
              if configuration[:middleware_names] && env['RESPONSE_MIDDLEWARE']
                "#{env['RESPONSE_MIDDLEWARE']}##{original_request_method}"
              elsif trace.resource_override?
                trace.resource
              else
                "#{original_request_method} #{status}".strip
              end

            # Overrides the trace resource if it never been set
            # Otherwise, the getter method would delegate to its root span
            trace.resource = request_span.resource unless trace.resource_override?

            request_span.set_tag(Tracing::Metadata::Ext::TAG_COMPONENT, Ext::TAG_COMPONENT)
            request_span.set_tag(Tracing::Metadata::Ext::TAG_OPERATION, Ext::TAG_OPERATION_REQUEST)
            request_span.set_tag(Tracing::Metadata::Ext::TAG_KIND, Tracing::Metadata::Ext::SpanKind::TAG_SERVER)

            if status != 404 && (last_route = trace.get_tag(Tracing::Metadata::Ext::HTTP::TAG_ROUTE))
              last_script_name = trace.get_tag(Tracing::Metadata::Ext::HTTP::TAG_ROUTE_PATH) || ''

              # If the last_script_name is empty but the env['SCRIPT_NAME'] is NOT empty
              # then the current rack request was not routed and must be accounted for
              # which only happens in pure nested rack requests i.e /rack/rack/hello/world
              #
              # To account for the unaccounted nested rack requests of /rack/hello/world,
              # we use 'PATH_INFO knowing that rack cannot have named parameters
              if last_script_name == '' && env['SCRIPT_NAME'] && env['SCRIPT_NAME'] != ''
                last_script_name = last_route
                last_route = env['PATH_INFO']
              end

              # Clear the route and route path tags from the request trace to avoid possibility of misplacement
              trace.clear_tag(Tracing::Metadata::Ext::HTTP::TAG_ROUTE)
              trace.clear_tag(Tracing::Metadata::Ext::HTTP::TAG_ROUTE_PATH)

              # Ensure tags are placed in rack.request span as desired
              request_span.set_tag(Tracing::Metadata::Ext::HTTP::TAG_ROUTE, last_script_name + last_route)
              request_span.clear_tag(Tracing::Metadata::Ext::HTTP::TAG_ROUTE_PATH)
            end

            # Set analytics sample rate
            if Contrib::Analytics.enabled?(configuration[:analytics_enabled])
              Contrib::Analytics.set_sample_rate(request_span, configuration[:analytics_sample_rate])
            end

            # Measure service stats
            Contrib::Analytics.set_measured(request_span)

            if request_span.get_tag(Tracing::Metadata::Ext::HTTP::TAG_METHOD).nil?
              request_span.set_tag(Tracing::Metadata::Ext::HTTP::TAG_METHOD, original_request_method)
            end

            url = parse_url(env, original_env)

            if request_span.get_tag(Tracing::Metadata::Ext::HTTP::TAG_URL).nil?
              options = configuration[:quantize] || {}

              # Quantization::HTTP.url base defaults to :show, but we are transitioning
              options[:base] ||= :exclude

              request_span.set_tag(
                Tracing::Metadata::Ext::HTTP::TAG_URL,
                Contrib::Utils::Quantization::HTTP.url(url, options)
              )
            end

            if request_span.get_tag(Tracing::Metadata::Ext::HTTP::TAG_BASE_URL).nil?
              options = configuration[:quantize]

              unless options[:base] == :show
                base_url = Contrib::Utils::Quantization::HTTP.base_url(url)

                unless base_url.empty?
                  request_span.set_tag(
                    Tracing::Metadata::Ext::HTTP::TAG_BASE_URL,
                    base_url
                  )
                end
              end
            end

            if request_span.get_tag(Tracing::Metadata::Ext::HTTP::TAG_CLIENT_IP).nil?
              Tracing::ClientIp.set_client_ip_tag(
                request_span,
                headers: request_header_collection,
                remote_ip: env['REMOTE_ADDR']
              )
            end

            if request_span.get_tag(Tracing::Metadata::Ext::HTTP::TAG_STATUS_CODE).nil? && status
              request_span.set_tag(Tracing::Metadata::Ext::HTTP::TAG_STATUS_CODE, status)
            end

            if request_span.get_tag(Tracing::Metadata::Ext::HTTP::TAG_USER_AGENT).nil? && user_agent
              request_span.set_tag(Tracing::Metadata::Ext::HTTP::TAG_USER_AGENT, user_agent)
            end

            if request_span.get_tag(Tracing::Metadata::Ext::HTTP::TAG_ROUTE).nil? && status != 404
              request_span.set_tag(Tracing::Metadata::Ext::HTTP::TAG_ROUTE, env['PATH_INFO'])
            end

            HeaderTagging.tag_request_headers(request_span, request_header_collection, configuration)
            HeaderTagging.tag_response_headers(request_span, headers, configuration) if headers

            # detect if the status code is a 5xx and flag the request span as an error
            # unless it has been already set by the underlying framework
            request_span.status = 1 if status.to_s.start_with?('5') && request_span.status.zero?
          end
          # rubocop:enable Metrics/AbcSize
          # rubocop:enable Metrics/CyclomaticComplexity
          # rubocop:enable Metrics/PerceivedComplexity
          # rubocop:enable Metrics/MethodLength

          private

          def configuration
            Datadog.configuration.tracing[:rack]
          end

          def parse_url(env, original_env)
            request_obj = ::Rack::Request.new(env)

            # scheme, host, and port
            base_url = if request_obj.respond_to?(:base_url)
                         request_obj.base_url
                       else
                         # Compatibility for older Rack versions
                         request_obj.url.chomp(request_obj.fullpath)
                       end

            # https://github.com/rack/rack/blob/main/SPEC.rdoc
            #
            # The source of truth in Rack is the PATH_INFO key that holds the
            # URL for the current request; but some frameworks may override that
            # value, especially during exception handling.
            #
            # Because of this, we prefer to use REQUEST_URI, if available, which is the
            # relative path + query string, and doesn't mutate.
            #
            # REQUEST_URI is only available depending on what web server is running though.
            # So when its not available, we want the original, unmutated PATH_INFO, which
            # is just the relative path without query strings.
            #
            # SCRIPT_NAME is the first part of the request URL path, so that
            # the application can know its virtual location. It should be
            # prepended to PATH_INFO to reflect the correct user visible path.
            request_uri = env['REQUEST_URI'].to_s
            fullpath = if request_uri.empty?
                         query_string = original_env['QUERY_STRING'].to_s
                         path = original_env['SCRIPT_NAME'].to_s + original_env['PATH_INFO'].to_s

                         query_string.empty? ? path : "#{path}?#{query_string}"
                       else
                         # normally REQUEST_URI starts at the path, but it
                         # might contain the full URL in some cases (e.g WEBrick)
                         request_uri.delete_prefix(base_url)
                       end

            base_url + fullpath
          end

          def parse_user_agent_header(headers)
            headers.get(Tracing::Metadata::Ext::HTTP::HEADER_USER_AGENT)
          end
        end
      end
    end
  end
end
