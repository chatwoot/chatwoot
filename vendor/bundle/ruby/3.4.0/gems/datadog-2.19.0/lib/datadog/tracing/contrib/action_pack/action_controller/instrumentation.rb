# frozen_string_literal: true

require_relative '../../../../tracing'
require_relative '../../../metadata/ext'

require_relative '../ext'
require_relative '../utils'
require_relative '../../rack/middlewares'
require_relative '../../analytics'
require_relative '../../../../core/telemetry/logger'

module Datadog
  module Tracing
    module Contrib
      module ActionPack
        module ActionController
          # Instrumentation for ActionController components
          module Instrumentation
            module_function

            def start_processing(payload)
              return unless Tracing.enabled?

              # trace the execution
              service = Datadog.configuration.tracing[:action_pack][:service_name]
              type = Tracing::Metadata::Ext::HTTP::TYPE_INBOUND
              span = Tracing.trace(
                Ext::SPAN_ACTION_CONTROLLER,
                service: service,
                type: type,
                resource: "#{payload.fetch(:controller)}##{payload.fetch(:action)}",
              )
              trace = Tracing.active_trace

              # attach the current span to the tracing context
              tracing_context = payload.fetch(:tracing_context)
              tracing_context[:dd_request_trace] = trace
              tracing_context[:dd_request_span] = span

              # We want the route to show up as the trace's resource
              trace.resource = span.resource unless payload[:headers][:request_exception]

              span.set_tag(Tracing::Metadata::Ext::TAG_COMPONENT, Ext::TAG_COMPONENT)
              span.set_tag(Tracing::Metadata::Ext::TAG_OPERATION, Ext::TAG_OPERATION_CONTROLLER)
            rescue StandardError => e
              Datadog.logger.error(e.message)
              Datadog::Core::Telemetry::Logger.report(e)
            end

            def finish_processing(payload)
              return unless Tracing.enabled?

              # retrieve the tracing context and the latest active span
              tracing_context = payload.fetch(:tracing_context)
              trace = tracing_context[:dd_request_trace]
              span = tracing_context[:dd_request_span]
              return unless span && !span.finished?

              begin
                # We repeat this in both start and at finish because the resource may have changed during the request
                trace.resource = span.resource unless payload[:headers][:request_exception]

                # Set analytics sample rate
                Utils.set_analytics_sample_rate(span)

                # Measure service stats
                Contrib::Analytics.set_measured(span)

                span.set_tag(Ext::TAG_ROUTE_ACTION, payload.fetch(:action))
                span.set_tag(Ext::TAG_ROUTE_CONTROLLER, payload.fetch(:controller))
                if (runtime = payload[:view_runtime])
                  span.set_tag(Ext::TAG_VIEW_RUNTIME, runtime)
                end
                if (runtime = payload[:db_runtime])
                  span.set_tag(Ext::TAG_DB_RUNTIME, runtime)
                end

                exception = payload[:exception_object]
                if exception.nil?
                  # [christian] in some cases :status is not defined,
                  # rather than firing an error, simply acknowledge we don't know it.
                  status = payload.fetch(:status, '?').to_s
                  span.status = 1 if status.start_with?('5')
                elsif Utils.exception_is_error?(exception)
                  span.set_error(exception)
                end
              ensure
                span.finish
              end
            rescue StandardError => e
              Datadog.logger.error(e.message)
              Datadog::Core::Telemetry::Logger.report(e)
            end

            # Instrumentation for ActionController::Metal
            module Metal
              # TODO: Refactor this method to avoid using async API that splits the logic
              # into two different methods (`start_processing` and `finish_processing`)
              def process_action(*args)
                # mutable payload with a tracing context that is used in two different
                # signals; it propagates the request span so that it can be finished
                # no matter what
                payload = {
                  controller: self.class,
                  action: action_name,
                  env: request.env,
                  headers: {
                    # The exception this controller was given in the request,
                    # which is typical if the controller is configured to handle exceptions.
                    request_exception: request.headers['action_dispatch.exception']
                  },
                  tracing_context: {}
                }

                begin
                  # process and catch request exceptions
                  Instrumentation.start_processing(payload)
                  result = super(*args)
                  status = datadog_response_status
                  payload[:status] = status unless status.nil?
                  result
                # rubocop:disable Lint/RescueException
                rescue Exception => e
                  payload[:exception] = [e.class.name, e.message]
                  payload[:exception_object] = e
                  raise e
                ensure
                  # Database and view runtime are available for controllers
                  # deriving from ActionController::Base.
                  # They are not defined on controllers deriving from
                  # ActionController::Metal, unless
                  # ActionController::Instrumentation is explicitly included
                  # into the controller class.
                  payload[:db_runtime] = db_runtime if respond_to?(:db_runtime)
                  payload[:view_runtime] = view_runtime if respond_to?(:view_runtime)
                end
              # rubocop:enable Lint/RescueException
              ensure
                Instrumentation.finish_processing(payload)
              end

              def datadog_response_status
                case response
                when ::ActionDispatch::Response
                  response.status
                when Array
                  # Likely a Rack response array: first element is the status.
                  status = response.first
                  status.class <= Integer ? status : nil
                end
              end
            end
          end
        end
      end
    end
  end
end
