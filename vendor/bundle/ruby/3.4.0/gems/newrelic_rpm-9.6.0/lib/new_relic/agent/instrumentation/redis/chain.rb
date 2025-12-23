# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic::Agent::Instrumentation
  module Redis
    module Chain
      def self.instrument!
        ::Redis::Client.class_eval do
          include NewRelic::Agent::Instrumentation::Redis

          if method_defined?(:call_v)
            alias_method(:call_v_without_new_relic, :call_v)

            def call_v(*args, &block)
              call_with_tracing(args[0]) { call_v_without_new_relic(*args, &block) }
            end
          end

          if method_defined?(:call)
            alias_method(:call_without_new_relic, :call)

            def call(*args, &block)
              call_with_tracing(args[0]) { call_without_new_relic(*args, &block) }
            end
          end

          if method_defined?(:call_pipeline)
            alias_method(:call_pipeline_without_new_relic, :call_pipeline)

            def call_pipeline(*args, &block)
              call_pipeline_with_tracing(args[0]) { call_pipeline_without_new_relic(*args, &block) }
            end
          end

          alias_method(:connect_without_new_relic, :connect)

          def connect(*args, &block)
            connect_with_tracing { connect_without_new_relic(*args, &block) }
          end
        end
      end
    end
  end
end
