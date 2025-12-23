# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module ConcurrentRuby
        # ConcurrentRuby integration constants
        # @public_api Changing resource names, tag names, or environment variables creates breaking changes.
        module Ext
          APP = 'concurrent-ruby'
          ENV_ENABLED = 'DD_TRACE_CONCURRENT_RUBY_ENABLED'
        end
      end
    end
  end
end
