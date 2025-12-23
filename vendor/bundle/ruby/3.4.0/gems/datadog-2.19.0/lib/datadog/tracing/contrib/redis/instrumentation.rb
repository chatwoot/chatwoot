# frozen_string_literal: true

require_relative '../patcher'
require_relative 'configuration/resolver'
require_relative 'ext'
require_relative 'quantize'
require_relative 'tags'
require_relative 'trace_middleware'

module Datadog
  module Tracing
    module Contrib
      module Redis
        # Instrumentation for Redis < 5
        module Instrumentation
          def self.included(base)
            base.prepend(InstanceMethods)
          end

          # InstanceMethods - implementing instrumentation
          module InstanceMethods
            def call(*args, &block)
              TraceMiddleware.call(self, args[0], service_name, command_args?) { super }
            end

            def call_pipeline(*args, &block)
              TraceMiddleware.call_pipelined(self, args[0].commands, service_name, command_args?) { super }
            end

            private

            def command_args?
              pinned = Datadog.configuration_for(self, :command_args)

              return pinned unless pinned.nil?

              datadog_configuration[:command_args]
            end

            def service_name
              Datadog.configuration_for(self, :service_name) ||
                datadog_configuration[:service_name]
            end

            def datadog_configuration
              Datadog.configuration.tracing[:redis, options]
            end
          end
        end
      end
    end
  end
end
