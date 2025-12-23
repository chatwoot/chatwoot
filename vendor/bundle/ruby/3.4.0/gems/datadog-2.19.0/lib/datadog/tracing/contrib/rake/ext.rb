# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module Rake
        # Rake integration constants
        # @public_api Changing resource names, tag names, or environment variables creates breaking changes.
        module Ext
          ENV_ENABLED = 'DD_TRACE_RAKE_ENABLED'
          # @!visibility private
          ENV_ANALYTICS_ENABLED = 'DD_TRACE_RAKE_ANALYTICS_ENABLED'
          ENV_ANALYTICS_SAMPLE_RATE = 'DD_TRACE_RAKE_ANALYTICS_SAMPLE_RATE'
          SERVICE_NAME = 'rake'
          SPAN_INVOKE = 'rake.invoke'
          SPAN_EXECUTE = 'rake.execute'
          TAG_EXECUTE_ARGS = 'rake.execute.args'
          TAG_INVOKE_ARGS = 'rake.invoke.args'
          TAG_TASK_ARG_NAMES = 'rake.task.arg_names'
          TAG_COMPONENT = 'rake'
          TAG_OPERATION_EXECUTE = 'execute'
          TAG_OPERATION_INVOKE = 'invoke'
        end
      end
    end
  end
end
