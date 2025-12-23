# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic::Agent::Instrumentation
  module ConcurrentRuby::Chain
    def self.instrument!
      ::Concurrent::ThreadPoolExecutor.class_eval do
        include NewRelic::Agent::Instrumentation::ConcurrentRuby

        alias_method(:post_without_new_relic, :post)

        def post(*args, &task)
          return post_without_new_relic(*args, &task) unless NewRelic::Agent::Tracer.tracing_enabled?

          traced_task = add_task_tracing(&task)
          post_without_new_relic(*args, &traced_task)
        end
      end

      [::Concurrent::Promises.const_get(:'InternalStates')::Rejected,
        ::Concurrent::Promises.const_get(:'InternalStates')::PartiallyRejected].each do |klass|
        klass.class_eval do
          alias_method(:initialize_without_new_relic, :initialize)

          # Uses args.last to record the error becuase the methods that this will monkey patch
          # look like: initialize(reason) & initialize(value, reason)
          def initialize(*args)
            NewRelic::Agent.notice_error(args.last) if args.last.is_a?(Exception)
            initialize_without_new_relic(*args)
          end
        end
      end
    end
  end
end
