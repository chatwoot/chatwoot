# frozen_string_literal: true

require_relative '../../metadata/ext'
require_relative '../analytics'
require_relative '../rack/ext'
require_relative '../rack/header_tagging'
require_relative 'env'
require_relative 'ext'

module Datadog
  module Tracing
    module Contrib
      module Sinatra
        # Middleware used for automatically tagging configured headers and handle request span
        class TracerMiddleware
          def initialize(app, opt = {})
            @app = app
            @app_instance = opt[:app_instance]
          end

          # rubocop:disable Metrics/MethodLength
          def call(env)
            # Find out if this is Sinatra within Sinatra
            return @app.call(env) if Sinatra::Env.datadog_span(env)

            Tracing.trace(
              Ext::SPAN_REQUEST,
              service: configuration[:service_name],
              type: Tracing::Metadata::Ext::HTTP::TYPE_INBOUND
            ) do |span|
              begin
                # this is kept nil until we set a correct one (either in the route or with a fallback in the ensure below)
                # the nil signals that there's no good one yet and is also seen by profiler, when sampling the resource
                span.resource = nil

                Sinatra::Env.set_datadog_span(env, span)

                response = @app.call(env)
              ensure
                Contrib::Rack::HeaderTagging.tag_request_headers(span, env, configuration)

                span.set_tag(Tracing::Metadata::Ext::TAG_COMPONENT, Ext::TAG_COMPONENT)
                span.set_tag(Tracing::Metadata::Ext::TAG_OPERATION, Ext::TAG_OPERATION_REQUEST)

                request = ::Sinatra::Request.new(env)

                span.set_tag(Tracing::Metadata::Ext::HTTP::TAG_URL, request.path)
                span.set_tag(Tracing::Metadata::Ext::HTTP::TAG_METHOD, request.request_method)

                datadog_route = Sinatra::Env.route_path(env)

                span.set_tag(Ext::TAG_ROUTE_PATH, datadog_route) if datadog_route

                if request.script_name && !request.script_name.empty?
                  span.set_tag(Ext::TAG_SCRIPT_NAME, request.script_name)
                end

                # If this app handled the request, then Contrib::Sinatra::Tracer OR Contrib::Sinatra::Base set the
                # resource; if no resource was set, let's use a fallback
                span.resource = env['REQUEST_METHOD'] if span.resource.nil?

                rack_request_span = env[Contrib::Rack::Ext::RACK_ENV_REQUEST_SPAN]

                # This propagates the Sinatra resource to the Rack span,
                # since the latter is unaware of what the resource might be
                # and would fallback to a generic resource name when unset
                rack_request_span.resource ||= span.resource if rack_request_span

                if response
                  if (status = response[0])
                    sinatra_response = ::Sinatra::Response.new([], status) # Build object to use status code helpers

                    span.set_tag(Tracing::Metadata::Ext::HTTP::TAG_STATUS_CODE, sinatra_response.status)
                    span.set_error(env['sinatra.error']) if sinatra_response.server_error?
                  end

                  if (headers = response[1])
                    Contrib::Rack::HeaderTagging.tag_response_headers(span, headers, configuration)
                  end
                end

                # Set analytics sample rate
                Contrib::Analytics.set_sample_rate(span, analytics_sample_rate) if analytics_enabled?

                # Measure service stats
                Contrib::Analytics.set_measured(span)
              end
            end
          end
          # rubocop:enable Metrics/MethodLength

          private

          def analytics_enabled?
            Contrib::Analytics.enabled?(configuration[:analytics_enabled])
          end

          def analytics_sample_rate
            configuration[:analytics_sample_rate]
          end

          def configuration
            Datadog.configuration.tracing[:sinatra]
          end
        end
      end
    end
  end
end
