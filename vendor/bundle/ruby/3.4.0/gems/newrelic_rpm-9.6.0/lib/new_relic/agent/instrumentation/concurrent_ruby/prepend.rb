# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic::Agent::Instrumentation
  module ConcurrentRuby
    module Prepend
      include NewRelic::Agent::Instrumentation::ConcurrentRuby

      def post(*args, &task)
        return super(*args, &task) unless NewRelic::Agent::Tracer.tracing_enabled?

        traced_task = add_task_tracing(&task)
        super(*args, &traced_task)
      end
    end

    module ErrorPrepend
      # Uses args.last to record the error because the methods that this will be prepended to
      # look like: initialize(reason) & initialize(value, reason)
      def initialize(*args)
        NewRelic::Agent.notice_error(args.last) if args.last.is_a?(Exception)
        super
      end
    end
  end
end
