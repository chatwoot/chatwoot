# frozen_string_literal: true

require_relative '../../../core'
require_relative '../../../core/telemetry/logger'
require_relative '../../metadata/ext'
require_relative '../analytics'
require_relative '../rack/ext'

module Datadog
  module Tracing
    module Contrib
      module Grape
        # Endpoint module includes a list of subscribers to create
        # traces when a Grape endpoint is hit
        module Endpoint
          KEY_RUN = 'datadog_grape_endpoint_run'
          KEY_RENDER = 'datadog_grape_endpoint_render'

          class << self
            def subscribe
              # subscribe when a Grape endpoint is hit
              ::ActiveSupport::Notifications.subscribe('endpoint_run.grape.start_process') do |*args|
                endpoint_start_process(*args)
              end
              ::ActiveSupport::Notifications.subscribe('endpoint_run.grape') do |*args|
                endpoint_run(*args)
              end
              ::ActiveSupport::Notifications.subscribe('endpoint_render.grape.start_render') do |*args|
                endpoint_start_render(*args)
              end
              ::ActiveSupport::Notifications.subscribe('endpoint_render.grape') do |*args|
                endpoint_render(*args)
              end
              ::ActiveSupport::Notifications.subscribe('endpoint_run_filters.grape') do |*args|
                endpoint_run_filters(*args)
              end
            end

            def endpoint_start_process(_name, _start, _finish, _id, payload)
              return if Thread.current[KEY_RUN]
              return unless enabled?

              # collect endpoint details
              endpoint = payload.fetch(:endpoint)
              env = payload.fetch(:env)
              api_view = api_view(endpoint.options[:for])
              request_method = endpoint.options.fetch(:method).first
              path = endpoint_expand_path(endpoint)
              resource = "#{api_view} #{request_method} #{path}"

              # Store the beginning of a trace
              span = Tracing.trace(
                Ext::SPAN_ENDPOINT_RUN,
                service: service_name,
                type: Tracing::Metadata::Ext::HTTP::TYPE_INBOUND,
                resource: resource
              )
              trace = Tracing.active_trace

              # Set the trace resource
              trace.resource = span.resource

              span.set_tag(Tracing::Metadata::Ext::TAG_COMPONENT, Ext::TAG_COMPONENT)
              span.set_tag(Tracing::Metadata::Ext::TAG_OPERATION, Ext::TAG_OPERATION_ENDPOINT_RUN)

              if (grape_route = env['grape.routing_args']) && grape_route[:route_info]
                trace.set_tag(
                  Tracing::Metadata::Ext::HTTP::TAG_ROUTE,
                  # here we are removing the format from the path:
                  # e.g. /path/to/resource(.json) => /path/to/resource
                  # e.g. /path/to/resource(.:format) => /path/to/resource
                  grape_route[:route_info].path&.gsub(/\(\.:?\w+\)\z/, '')
                )

                trace.set_tag(Tracing::Metadata::Ext::HTTP::TAG_ROUTE_PATH, env['SCRIPT_NAME'])
              end

              Thread.current[KEY_RUN] = true
            rescue StandardError => e
              Datadog.logger.error(e.message)
              Datadog::Core::Telemetry::Logger.report(e)
            end

            def endpoint_run(name, start, finish, id, payload)
              return unless Thread.current[KEY_RUN]

              Thread.current[KEY_RUN] = false

              return unless enabled?

              trace = Tracing.active_trace
              span = Tracing.active_span
              return unless trace && span

              begin
                # collect endpoint details
                endpoint = payload.fetch(:endpoint)
                api_view = api_view(endpoint.options[:for])
                request_method = endpoint.options.fetch(:method).first
                path = endpoint_expand_path(endpoint)

                trace.resource = span.resource

                # Set analytics sample rate
                Contrib::Analytics.set_sample_rate(span, analytics_sample_rate) if analytics_enabled?

                # Measure service stats
                Contrib::Analytics.set_measured(span)

                handle_error_and_status_code(span, endpoint, payload)

                # override the current span with this notification values
                span.set_tag(Ext::TAG_ROUTE_ENDPOINT, api_view) unless api_view.nil?
                span.set_tag(Ext::TAG_ROUTE_PATH, path)
                span.set_tag(Ext::TAG_ROUTE_METHOD, request_method)

                span.set_tag(Tracing::Metadata::Ext::HTTP::TAG_METHOD, request_method)
                span.set_tag(Tracing::Metadata::Ext::HTTP::TAG_URL, path)
              ensure
                span.start(start)
                span.finish(finish)
              end
            rescue StandardError => e
              Datadog.logger.error(e.message)
              Datadog::Core::Telemetry::Logger.report(e)
            end

            # Status code resolution is tied to the exception handling
            def handle_error_and_status_code(span, endpoint, payload)
              status = nil

              # Handle exceptions and status code
              if (exception_object = payload[:exception_object])
                # If the exception is not an internal Grape error, we won't have a status code at this point.
                status = exception_object.status if exception_object.respond_to?(:status)

                handle_error(span, exception_object, status)
              else
                # Status code is unreliable in `endpoint_run.grape` if there was an exception.
                # Only after `Grape::Middleware::Error#run_rescue_handler` that the error status code of a request with a
                # Ruby exception error is resolved. But that handler is called further down the Grape middleware stack.
                # Rack span will then be the most reliable source for status codes.
                # DEV: As a corollary, instrumenting Grape without Rack will provide incomplete
                # DEV: status quote information.
                status = endpoint.status
                span.set_error(endpoint) if error_status_codes.include?(status)
              end

              span.set_tag(Tracing::Metadata::Ext::HTTP::TAG_STATUS_CODE, status) if status
            end

            def endpoint_start_render(*)
              return if Thread.current[KEY_RENDER]
              return unless enabled?

              # Store the beginning of a trace
              span = Tracing.trace(
                Ext::SPAN_ENDPOINT_RENDER,
                service: service_name,
                type: Tracing::Metadata::Ext::HTTP::TYPE_TEMPLATE
              )

              span.set_tag(Tracing::Metadata::Ext::TAG_COMPONENT, Ext::TAG_COMPONENT)
              span.set_tag(Tracing::Metadata::Ext::TAG_OPERATION, Ext::TAG_OPERATION_ENDPOINT_RENDER)

              Thread.current[KEY_RENDER] = true
            rescue StandardError => e
              Datadog.logger.error(e.message)
              Datadog::Core::Telemetry::Logger.report(e)
            end

            def endpoint_render(name, start, finish, id, payload)
              return unless Thread.current[KEY_RENDER]

              Thread.current[KEY_RENDER] = false

              return unless enabled?

              span = Tracing.active_span
              return unless span

              # catch thrown exceptions
              begin
                # Measure service stats
                Contrib::Analytics.set_measured(span)

                handle_error(span, payload[:exception_object]) if payload[:exception_object]
              ensure
                span.start(start)
                span.finish(finish)
              end
            rescue StandardError => e
              Datadog.logger.error(e.message)
              Datadog::Core::Telemetry::Logger.report(e)
            end

            def endpoint_run_filters(name, start, finish, id, payload)
              return unless enabled?

              # safe-guard to prevent submitting empty filters
              zero_length = (finish - start).zero?
              filters = payload[:filters]
              type = payload[:type]
              return if (!filters || filters.empty?) || !type || zero_length

              span = Tracing.trace(
                Ext::SPAN_ENDPOINT_RUN_FILTERS,
                service: service_name,
                type: Tracing::Metadata::Ext::HTTP::TYPE_INBOUND,
                start_time: start
              )

              begin
                span.set_tag(Tracing::Metadata::Ext::TAG_COMPONENT, Ext::TAG_COMPONENT)
                span.set_tag(Tracing::Metadata::Ext::TAG_OPERATION, Ext::TAG_OPERATION_ENDPOINT_RUN_FILTERS)

                # Set analytics sample rate
                Contrib::Analytics.set_sample_rate(span, analytics_sample_rate) if analytics_enabled?

                # Measure service stats
                Contrib::Analytics.set_measured(span)

                # catch thrown exceptions
                handle_error(span, payload[:exception_object]) if payload[:exception_object]

                span.set_tag(Ext::TAG_FILTER_TYPE, type.to_s)
              ensure
                span.start(start)
                span.finish(finish)
              end
            rescue StandardError => e
              Datadog.logger.error(e.message)
              Datadog::Core::Telemetry::Logger.report(e)
            end

            private

            def handle_error(span, exception, status = nil)
              status ||= (exception.status if exception.respond_to?(:status))
              if status
                span.set_error(exception) if error_status_codes.include?(status)
              else
                on_error.call(span, exception)
              end
            end

            def error_status_codes
              datadog_configuration[:error_status_codes]
            end

            def on_error
              datadog_configuration[:on_error] || Tracing::SpanOperation::Events::DEFAULT_ON_ERROR
            end

            def api_view(api)
              # If the API inherits from Grape::API in version >= 1.2.0
              # then the API will be an instance and the name must be derived from the base.
              # See https://github.com/ruby-grape/grape/issues/1825
              if defined?(::Grape::API::Instance) && api <= ::Grape::API::Instance
                api.base.to_s
              else
                api.to_s
              end
            end

            def endpoint_expand_path(endpoint)
              route_path = endpoint.options[:path]
              namespace = endpoint.routes.first && endpoint.routes.first.namespace || ''

              path = (namespace.split('/') + route_path)
                .reject { |p| p.blank? || p.eql?('/') }
                .join('/')
              path.prepend('/') if path[0] != '/'
              path
            end

            def service_name
              datadog_configuration[:service_name]
            end

            def analytics_enabled?
              Contrib::Analytics.enabled?(datadog_configuration[:analytics_enabled])
            end

            def analytics_sample_rate
              datadog_configuration[:analytics_sample_rate]
            end

            def exception_is_error?(exception)
              return false unless exception
              return true unless exception.respond_to?(:status)

              error_status?(status.exception)
            end

            def error_status?(status)
              matcher = datadog_configuration[:error_statuses]
              return true unless matcher

              matcher.include?(status) if matcher
            end

            def enabled?
              Datadog.configuration.tracing.enabled && \
                datadog_configuration[:enabled] == true
            end

            def datadog_configuration
              Datadog.configuration.tracing[:grape]
            end
          end
        end
      end
    end
  end
end
