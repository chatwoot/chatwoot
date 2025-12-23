# frozen_string_literal: true

require_relative 'context_composite_executor_service'

module Datadog
  module Tracing
    module Contrib
      module ConcurrentRuby
        # This patches the Future - to wrap executor service using ContextCompositeExecutorService
        module FuturePatch
          def ns_initialize(value, opts)
            super(value, opts)

            @executor = ContextCompositeExecutorService.new(@executor)
          end
        end
      end
    end
  end
end
