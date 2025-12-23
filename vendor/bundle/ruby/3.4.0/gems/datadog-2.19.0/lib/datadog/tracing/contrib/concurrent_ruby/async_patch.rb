# frozen_string_literal: true

require_relative 'context_composite_executor_service'

module Datadog
  module Tracing
    module Contrib
      module ConcurrentRuby
        # This patches the Async - to wrap executor service using ContextCompositeExecutorService
        module AsyncPatch
          def initialize(delegate)
            super(delegate)

            @executor = ContextCompositeExecutorService.new(@executor)
          end
        end
      end
    end
  end
end
