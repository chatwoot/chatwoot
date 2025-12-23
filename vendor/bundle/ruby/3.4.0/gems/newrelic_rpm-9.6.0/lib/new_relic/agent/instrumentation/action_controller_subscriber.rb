# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/instrumentation/notifications_subscriber'
require 'new_relic/agent/instrumentation/ignore_actions'
require 'new_relic/agent/parameter_filtering'

module NewRelic
  module Agent
    module Instrumentation
      class ActionControllerSubscriber < NotificationsSubscriber
        def start(name, id, payload) # THREAD_LOCAL_ACCESS
          controller_class = controller_class(payload)

          if state.is_execution_traced? && !should_ignore(payload, controller_class)
            finishable = start_transaction_or_segment(payload, request_for_payload(payload), controller_class)
            push_segment(id, finishable)
          else
            # if this transaction is ignored, make sure child
            # transaction are also ignored
            state.current_transaction&.ignore!
            NewRelic::Agent.instance.push_trace_execution_flag(false)
          end
        rescue => e
          log_notification_error(e, name, 'start')
        end

        def finish(name, id, payload) # THREAD_LOCAL_ACCESS
          finishable = pop_segment(id)

          if state.is_execution_traced? \
              && !should_ignore(payload, controller_class(payload))

            if exception = exception_object(payload)
              finishable.notice_error(exception)
            end

            finishable.finish
          else
            Agent.instance.pop_trace_execution_flag
          end
        rescue => e
          log_notification_error(e, name, 'finish')
        end

        def start_transaction_or_segment(payload, request, controller_class)
          Tracer.start_transaction_or_segment(
            name: format_metric_name(payload[:action], controller_class),
            category: :controller,
            options: tracer_options(payload, request, controller_class)
          )
        end

        def tracer_options(payload, request, controller_class)
          {
            request: request,
            filtered_params: filtered_params(payload[:params]),
            apdex_start_time: queue_start(request),
            ignore_apdex: ignore?(payload[:action], ControllerInstrumentation::NR_IGNORE_APDEX_KEY, controller_class),
            ignore_enduser: ignore?(payload[:action],
              ControllerInstrumentation::NR_IGNORE_ENDUSER_KEY,
              controller_class)
          }.merge(NewRelic::Agent::MethodTracerHelpers.code_information(controller_class, payload[:action]))
        end

        def filtered_params(params)
          NewRelic::Agent::ParameterFiltering.filter_using_rails(params, Rails.application.config.filter_parameters)
        end

        def ignore?(action, key, controller_class)
          NewRelic::Agent::Instrumentation::IgnoreActions.is_filtered?(key, controller_class, action)
        end

        def format_metric_name(metric_action, controller)
          controller_class = controller.is_a?(Class) ? controller : Object.const_get(controller)
          "Controller/#{controller_class.controller_path}/#{metric_action}"
        end

        def controller_class(payload)
          ::NewRelic::LanguageSupport.constantize(payload[:controller])
        end

        def should_ignore(payload, controller_class)
          NewRelic::Agent::Instrumentation::IgnoreActions.is_filtered?(
            ControllerInstrumentation::NR_DO_NOT_TRACE_KEY,
            controller_class,
            payload[:action]
          )
        end

        def queue_start(request)
          # the following line needs else branch coverage
          if request && request.respond_to?(:env) # rubocop:disable Style/SafeNavigation
            QueueTime.parse_frontend_timestamp(request.env, Process.clock_gettime(Process::CLOCK_REALTIME))
          end
        end

        def request_for_payload(payload)
          # @req is a historically stable but not guaranteed Rails header property
          return unless payload[:headers].instance_variables.include?(:@req)

          payload[:headers].instance_variable_get(:@req)
        end
      end
    end
  end
end
