# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    module Instrumentation
      module DelayedJob
        def initialize_with_tracing
          yield
          worker_name = case
                        when self.respond_to?(:name) then self.name
                        when self.class.respond_to?(:default_name) then self.class.default_name
          end
          NewRelic::DelayedJobInjection.worker_name = worker_name

          # TODO: Refactor the last line of this condition so that it can be evaluated in both prepend and chain instrumentation
          if defined?(::Delayed::Job) && ::Delayed::Job.method_defined?(:invoke_job) &&
              !(::Delayed::Job.method_defined?(:invoke_job_without_new_relic))

            ::NewRelic::Agent.logger.info('Installing DelayedJob instrumentation [part 2/2]')
            install_newrelic_job_tracer
            NewRelic::Control.instance.init_plugin(:dispatcher => :delayed_job)
          else
            NewRelic::Agent.logger.warn('Did not find a Delayed::Job class responding to invoke_job, aborting DJ instrumentation')
          end
        end
      end

      module DelayedJobTracer
        include NewRelic::Agent::Instrumentation::ControllerInstrumentation

        NR_TRANSACTION_CATEGORY = 'OtherTransaction/DelayedJob'.freeze
        INSTRUMENTATION_NAME = 'DelayedJob'

        def invoke_job_with_tracing
          NewRelic::Agent.record_instrumentation_invocation(INSTRUMENTATION_NAME)

          options = {
            :category => NR_TRANSACTION_CATEGORY,
            :path => ::NewRelic::Agent::Instrumentation::DelayedJob::Naming.name_from_payload(payload_object)
          }

          perform_action_with_newrelic_trace(options) do
            yield
          end
        end
      end
    end
  end
end
