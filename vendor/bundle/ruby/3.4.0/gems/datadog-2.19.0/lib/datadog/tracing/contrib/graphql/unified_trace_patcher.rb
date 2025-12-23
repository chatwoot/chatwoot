# frozen_string_literal: true

if Gem.loaded_specs['graphql'] && Gem.loaded_specs['graphql'].version >= Gem::Version.new('2.0.19')
  require_relative 'unified_trace'
end

module Datadog
  module Tracing
    module Contrib
      module GraphQL
        # Provides instrumentation for `graphql` through the GraphQL's tracing with methods defined in UnifiedTrace
        module UnifiedTracePatcher
          module_function

          # TODO: `GraphQL::Schema.trace_with` and `YOUR_SCHEMA.trace_with` don't mix.
          # TODO: They create duplicate spans when combined.
          # TODO: We should measure how frequently users use `YOUR_SCHEMA.trace_with`, and hopefully we can remove it.
          def patch!(schemas)
            if schemas.empty?
              ::GraphQL::Schema.trace_with(UnifiedTrace)
            else
              schemas.each do |schema|
                schema.trace_with(UnifiedTrace)
              end
            end
          end
        end
      end
    end
  end
end
