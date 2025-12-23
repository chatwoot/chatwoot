# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative 'instrumentation'

module NewRelic
  module Agent
    module Instrumentation
      module DelayedJob
        module Prepend
          include NewRelic::Agent::Instrumentation::DelayedJob

          def initialize(*args)
            initialize_with_tracing { super }
          end

          def install_newrelic_job_tracer
            Delayed::Job.send(:prepend, ::NewRelic::Agent::Instrumentation::DelayedJobTracerPrepend)
          end
        end
      end

      module DelayedJobTracerPrepend
        include NewRelic::Agent::Instrumentation::DelayedJobTracer

        def invoke_job(*args, &block)
          invoke_job_with_tracing { super }
        end
      end
    end
  end
end
