# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module GraphQL
        # GraphQL integration constants
        # @public_api Changing resource names, tag names, or environment variables creates breaking changes.
        module Ext
          ENV_ENABLED = 'DD_TRACE_GRAPHQL_ENABLED'
          # @!visibility private
          ENV_ANALYTICS_ENABLED = 'DD_TRACE_GRAPHQL_ANALYTICS_ENABLED'
          ENV_ANALYTICS_SAMPLE_RATE = 'DD_TRACE_GRAPHQL_ANALYTICS_SAMPLE_RATE'
          ENV_WITH_UNIFIED_TRACER = 'DD_TRACE_GRAPHQL_WITH_UNIFIED_TRACER'
          ENV_ERROR_EXTENSIONS = 'DD_TRACE_GRAPHQL_ERROR_EXTENSIONS'
          SERVICE_NAME = 'graphql'
          TAG_COMPONENT = 'graphql'

          # Span event name for query-level errors
          EVENT_QUERY_ERROR = 'dd.graphql.query.error'
        end
      end
    end
  end
end
