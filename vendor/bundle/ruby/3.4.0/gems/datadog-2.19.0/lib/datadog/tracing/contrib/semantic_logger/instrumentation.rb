# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module SemanticLogger
        # Instrumentation for SemanticLogger
        module Instrumentation
          def self.included(base)
            base.prepend(InstanceMethods)
          end

          # Instance methods for configuration
          module InstanceMethods
            def log(log, message = nil, progname = nil, &block)
              return super unless Datadog.configuration.tracing.log_injection
              return super unless Datadog.configuration.tracing[:semantic_logger].enabled
              return super unless log.is_a?(::SemanticLogger::Log)

              original_named_tags = log.named_tags || {}

              # Retrieves trace information for current thread
              correlation = Tracing.correlation

              # if the user already has conflicting log_tags
              # we want them to clobber ours, because we should allow them to override if needed.
              log.named_tags = correlation.to_h.merge(original_named_tags)
              super(log, message, progname, &block)
            end
          end
        end
      end
    end
  end
end
