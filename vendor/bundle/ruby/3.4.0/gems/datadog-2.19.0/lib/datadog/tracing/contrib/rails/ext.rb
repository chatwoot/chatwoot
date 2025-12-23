# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module Rails
        # Rails integration constants
        # @public_api Changing resource names, tag names, or environment variables creates breaking changes.
        module Ext
          APP = 'rails'
          ENV_ENABLED = 'DD_TRACE_RAILS_ENABLED'
          # @!visibility private
          ENV_ANALYTICS_ENABLED = 'DD_TRACE_RAILS_ANALYTICS_ENABLED'
          ENV_ANALYTICS_SAMPLE_RATE = 'DD_TRACE_RAILS_ANALYTICS_SAMPLE_RATE'
          ENV_DISABLE = 'DISABLE_DATADOG_RAILS'

          SPAN_RUNNER_FILE = 'rails.runner.file'
          SPAN_RUNNER_INLINE = 'rails.runner.inline'
          SPAN_RUNNER_STDIN = 'rails.runner.stdin'
          TAG_COMPONENT = 'rails'
          TAG_OPERATION_FILE = 'runner.file'
          TAG_OPERATION_INLINE = 'runner.inline'
          TAG_OPERATION_STDIN = 'runner.stdin'
          TAG_RUNNER_SOURCE = 'source'

          # @!visibility private
          MINIMUM_VERSION = Gem::Version.new('4')
        end
      end
    end
  end
end
