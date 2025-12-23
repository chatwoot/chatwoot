# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative 'instrumentation'

module NewRelic::Agent::Instrumentation
  module DelayedJob
    module Chain
      def self.instrument!
        Delayed::Worker.class_eval do
          include NewRelic::Agent::Instrumentation::DelayedJob

          def initialize_with_new_relic(*args)
            initialize_with_tracing { initialize_without_new_relic(*args) }
          end

          alias initialize_without_new_relic initialize
          alias initialize initialize_with_new_relic

          def install_newrelic_job_tracer
            Delayed::Job.class_eval do
              include NewRelic::Agent::Instrumentation::DelayedJobTracer

              alias_method(:invoke_job_without_new_relic, :invoke_job)

              def invoke_job(*args, &block)
                invoke_job_with_tracing { invoke_job_without_new_relic(*args, &block) }
              end
            end
          end
        end
      end
    end
  end
end
