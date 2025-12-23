# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module Grape
        # Grape integration constants
        # @public_api Changing resource names, tag names, or environment variables creates breaking changes.
        module Ext
          ENV_ENABLED = 'DD_TRACE_GRAPE_ENABLED'
          # @!visibility private
          ENV_ANALYTICS_ENABLED = 'DD_TRACE_GRAPE_ANALYTICS_ENABLED'
          ENV_ANALYTICS_SAMPLE_RATE = 'DD_TRACE_GRAPE_ANALYTICS_SAMPLE_RATE'
          ENV_ERROR_STATUS_CODES = 'DD_TRACE_GRAPE_ERROR_STATUS_CODES'
          SPAN_ENDPOINT_RENDER = 'grape.endpoint_render'
          SPAN_ENDPOINT_RUN = 'grape.endpoint_run'
          SPAN_ENDPOINT_RUN_FILTERS = 'grape.endpoint_run_filters'
          TAG_COMPONENT = 'grape'
          TAG_FILTER_TYPE = 'grape.filter.type'
          TAG_OPERATION_ENDPOINT_RENDER = 'endpoint_render'
          TAG_OPERATION_ENDPOINT_RUN = 'endpoint_run'
          TAG_OPERATION_ENDPOINT_RUN_FILTERS = 'endpoint_run_filters'
          TAG_ROUTE_ENDPOINT = 'grape.route.endpoint'
          TAG_ROUTE_PATH = 'grape.route.path'
          TAG_ROUTE_METHOD = 'grape.route.method'
        end
      end
    end
  end
end
