# frozen_string_literal: true

require_relative 'context_composite_executor_service'

module Datadog
  module Tracing
    module Contrib
      module ConcurrentRuby
        # This patches the Future - to wrap executor service using ContextCompositeExecutorService
        module PromisesFuturePatch
          def future_on(default_executor, *args, &task)
            unless default_executor.is_a?(ContextCompositeExecutorService)
              default_executor = ContextCompositeExecutorService.new(default_executor)
            end

            super(default_executor, *args, &task)
          end
        end
      end
    end
  end
end
