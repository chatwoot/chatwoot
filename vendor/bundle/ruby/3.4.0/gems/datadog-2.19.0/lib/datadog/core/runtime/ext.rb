# frozen_string_literal: true

module Datadog
  module Core
    module Runtime
      # @public_api
      module Ext
        TAG_ID = 'runtime-id'
        TAG_LANG = 'language'
        TAG_PROCESS_ID = 'process_id'

        # Metrics
        # @public_api
        module Metrics
          ENV_ENABLED = 'DD_RUNTIME_METRICS_ENABLED'
          ENV_OTEL_METRICS_EXPORTER = 'OTEL_METRICS_EXPORTER'

          METRIC_CLASS_COUNT = 'runtime.ruby.class_count'
          METRIC_GC_PREFIX = 'runtime.ruby.gc'
          METRIC_THREAD_COUNT = 'runtime.ruby.thread_count'
          METRIC_GLOBAL_CONSTANT_STATE = 'runtime.ruby.global_constant_state'
          METRIC_GLOBAL_METHOD_STATE = 'runtime.ruby.global_method_state'
          METRIC_CONSTANT_CACHE_INVALIDATIONS = 'runtime.ruby.constant_cache_invalidations'
          METRIC_CONSTANT_CACHE_MISSES = 'runtime.ruby.constant_cache_misses'
          METRIC_YJIT_CODE_GC_COUNT = 'runtime.ruby.yjit.code_gc_count'
          METRIC_YJIT_CODE_REGION_SIZE = 'runtime.ruby.yjit.code_region_size'
          METRIC_YJIT_FREED_CODE_SIZE = 'runtime.ruby.yjit.freed_code_size'
          METRIC_YJIT_FREED_PAGE_COUNT = 'runtime.ruby.yjit.freed_page_count'
          METRIC_YJIT_INLINE_CODE_SIZE = 'runtime.ruby.yjit.inline_code_size'
          METRIC_YJIT_LIVE_PAGE_COUNT = 'runtime.ruby.yjit.live_page_count'
          METRIC_YJIT_OBJECT_SHAPE_COUNT = 'runtime.ruby.yjit.object_shape_count'
          METRIC_YJIT_OUTLINED_CODE_SIZE = 'runtime.ruby.yjit.outlined_code_size'
          METRIC_YJIT_YJIT_ALLOC_SIZE = 'runtime.ruby.yjit.yjit_alloc_size'
          METRIC_YJIT_RATIO_IN_YJIT = 'runtime.ruby.yjit.ratio_in_yjit'

          TAG_SERVICE = 'service'
        end
      end
    end
  end
end
