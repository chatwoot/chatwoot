# frozen_string_literal: true

require_relative '../analytics'
require_relative '../patcher'
require_relative 'tracing_patcher'
require_relative 'trace_patcher'
require_relative 'unified_trace_patcher'

module Datadog
  module Tracing
    module Contrib
      module GraphQL
        # Provides instrumentation for `graphql` through the GraphQL tracing framework
        module Patcher
          include Contrib::Patcher

          module_function

          def target_version
            Integration.version
          end

          def patch
            # DEV-3.0: We should remove as many patching options as possible, given the alternatives do not
            # DEV-3.0: provide any benefit to the recommended `with_unified_tracer` patching method.
            # DEV-3.0: `with_deprecated_tracer` is likely safe to remove.
            # DEV-3.0: `with_unified_tracer: false` should be removed if possible.
            # DEV-3.0: `with_unified_tracer: true` should be the default and hopefully not even necessary as an option.
            if configuration[:with_deprecated_tracer]
              TracingPatcher.patch!(schemas)
            elsif Integration.trace_supported?
              if configuration[:with_unified_tracer]
                UnifiedTracePatcher.patch!(schemas)
              else
                TracePatcher.patch!(schemas)
              end
            else
              Datadog.logger.warn(
                "GraphQL version (#{target_version}) does not support GraphQL::Tracing::DataDogTrace"\
                'or Datadog::Tracing::Contrib::GraphQL::UnifiedTrace.'\
                'Falling back to GraphQL::Tracing::DataDogTracing.'
              )
              TracingPatcher.patch!(schemas)
            end
          end

          def configuration
            Datadog.configuration.tracing[:graphql]
          end

          def schemas
            configuration[:schemas]
          end
        end
      end
    end
  end
end
