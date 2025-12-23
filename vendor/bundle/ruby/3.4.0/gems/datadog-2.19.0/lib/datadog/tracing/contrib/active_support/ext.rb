# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module ActiveSupport
        # ActiveSupport integration constants
        # @public_api Changing resource names, tag names, or environment variables creates breaking changes.
        module Ext
          ENV_ENABLED = 'DD_TRACE_ACTIVE_SUPPORT_ENABLED'
          # @!visibility private
          ENV_ANALYTICS_ENABLED = 'DD_TRACE_ACTIVE_SUPPORT_ANALYTICS_ENABLED'
          ENV_ANALYTICS_SAMPLE_RATE = 'DD_TRACE_ACTIVE_SUPPORT_ANALYTICS_SAMPLE_RATE'
          QUANTIZE_CACHE_MAX_KEY_SIZE = 300
          RESOURCE_CACHE_DELETE = 'DELETE'
          RESOURCE_CACHE_GET = 'GET'
          RESOURCE_CACHE_MGET = 'MGET'
          RESOURCE_CACHE_SET = 'SET'
          RESOURCE_CACHE_MSET = 'MSET'
          SERVICE_CACHE = 'active_support-cache'
          SPAN_CACHE = 'rails.cache'
          SPAN_TYPE_CACHE = 'cache'
          TAG_CACHE_BACKEND = 'rails.cache.backend'
          TAG_CACHE_KEY = 'rails.cache.key'
          TAG_CACHE_KEY_MULTI = 'rails.cache.keys'
          TAG_COMPONENT = 'active_support'
          TAG_OPERATION_CACHE = 'cache'
        end
      end
    end
  end
end
