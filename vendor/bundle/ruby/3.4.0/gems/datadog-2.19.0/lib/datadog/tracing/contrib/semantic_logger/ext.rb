# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module SemanticLogger
        # SemanticLogger integration constants
        # @public_api Changing resource names, tag names, or environment variables creates breaking changes.
        module Ext
          ENV_ENABLED = 'DD_TRACE_SEMANTIC_LOGGER_ENABLED'
        end
      end
    end
  end
end
