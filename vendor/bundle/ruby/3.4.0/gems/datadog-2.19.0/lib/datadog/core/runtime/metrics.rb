# frozen_string_literal: true

require_relative 'ext'

require_relative '../metrics/client'
require_relative '../environment/class_count'
require_relative '../environment/gc'
require_relative '../environment/thread_count'
require_relative '../environment/vm_cache'
require_relative '../environment/yjit'

module Datadog
  module Core
    module Runtime
      # For generating runtime metrics
      class Metrics < Core::Metrics::Client
        def initialize(telemetry:, **options)
          super

          # Initialize service list
          @services = Set.new(options.fetch(:services, []))
          @service_tags = nil
          compile_service_tags!

          # Initialize the collection of runtime-id
          @runtime_id_enabled = options.fetch(:experimental_runtime_id_enabled, false)
        end

        # Associate service with runtime metrics
        def register_service(service)
          return unless enabled? && service

          service = service.to_s

          unless @services.include?(service)
            # Add service to list and update services tag
            services << service

            # Recompile the service tags
            compile_service_tags!
          end
        end

        # Flush all runtime metrics to Statsd client
        def flush
          return unless enabled?

          try_flush do
            if Core::Environment::ClassCount.available?
              gauge(Core::Runtime::Ext::Metrics::METRIC_CLASS_COUNT, Core::Environment::ClassCount.value)
            end
          end

          try_flush do
            if Core::Environment::ThreadCount.available?
              gauge(Core::Runtime::Ext::Metrics::METRIC_THREAD_COUNT, Core::Environment::ThreadCount.value)
            end
          end

          try_flush { gc_metrics.each { |metric, value| gauge(metric, value) } if Core::Environment::GC.available? }

          try_flush do
            if Core::Environment::VMCache.available?
              # Only on Ruby < 3.2
              gauge_if_not_nil(
                Core::Runtime::Ext::Metrics::METRIC_GLOBAL_CONSTANT_STATE,
                Core::Environment::VMCache.global_constant_state
              )

              # Only on Ruby 2.x
              gauge_if_not_nil(
                Core::Runtime::Ext::Metrics::METRIC_GLOBAL_METHOD_STATE,
                Core::Environment::VMCache.global_method_state
              )

              # Only on Ruby >= 3.2
              gauge_if_not_nil(
                Core::Runtime::Ext::Metrics::METRIC_CONSTANT_CACHE_INVALIDATIONS,
                Core::Environment::VMCache.constant_cache_invalidations
              )
              gauge_if_not_nil(
                Core::Runtime::Ext::Metrics::METRIC_CONSTANT_CACHE_MISSES,
                Core::Environment::VMCache.constant_cache_misses
              )
            end
          end

          flush_yjit_stats
        end

        def gc_metrics
          Core::Environment::GC.stat.flat_map do |k, v|
            nested_gc_metric(Core::Runtime::Ext::Metrics::METRIC_GC_PREFIX, k, v)
          end.to_h
        end

        def try_flush
          yield
        rescue => e
          Datadog.logger.warn("Error while sending runtime metric. Cause: #{e.class.name} #{e.message}")
        end

        def default_metric_options
          # Return dupes, so that the constant isn't modified,
          # and defaults are unfrozen for mutation in Statsd.
          super.tap do |options|
            options[:tags] = options[:tags].dup

            # Add services dynamically because they might change during runtime.
            options[:tags].concat(service_tags) unless service_tags.nil?

            # Add runtime-id dynamically because it might change during runtime.
            options[:tags].concat(["runtime-id:#{Core::Environment::Identity.id}"]) if @runtime_id_enabled
          end
        end

        private

        attr_reader \
          :service_tags,
          :services,
          :runtime_id_enabled

        def compile_service_tags!
          @service_tags = services.to_a.collect do |service|
            "#{Core::Runtime::Ext::Metrics::TAG_SERVICE}:#{service}"
          end
        end

        def nested_gc_metric(prefix, k, v)
          path = "#{prefix}.#{k}"

          if v.is_a?(Hash)
            v.flat_map do |key, value|
              nested_gc_metric(path, key, value)
            end
          else
            [[to_metric_name(path), v]]
          end
        end

        def to_metric_name(str)
          str.downcase.gsub(/[-\s]/, '_')
        end

        def gauge_if_not_nil(metric_name, metric_value)
          gauge(metric_name, metric_value) if metric_value
        end

        # standard:disable Metrics/MethodLength
        def flush_yjit_stats
          # Only on Ruby >= 3.2
          try_flush do
            if Core::Environment::YJIT.available?
              gauge_if_not_nil(
                Core::Runtime::Ext::Metrics::METRIC_YJIT_CODE_GC_COUNT,
                Core::Environment::YJIT.code_gc_count
              )
              gauge_if_not_nil(
                Core::Runtime::Ext::Metrics::METRIC_YJIT_CODE_REGION_SIZE,
                Core::Environment::YJIT.code_region_size
              )
              gauge_if_not_nil(
                Core::Runtime::Ext::Metrics::METRIC_YJIT_FREED_CODE_SIZE,
                Core::Environment::YJIT.freed_code_size
              )
              gauge_if_not_nil(
                Core::Runtime::Ext::Metrics::METRIC_YJIT_FREED_PAGE_COUNT,
                Core::Environment::YJIT.freed_page_count
              )
              gauge_if_not_nil(
                Core::Runtime::Ext::Metrics::METRIC_YJIT_INLINE_CODE_SIZE,
                Core::Environment::YJIT.inline_code_size
              )
              gauge_if_not_nil(
                Core::Runtime::Ext::Metrics::METRIC_YJIT_LIVE_PAGE_COUNT,
                Core::Environment::YJIT.live_page_count
              )
              gauge_if_not_nil(
                Core::Runtime::Ext::Metrics::METRIC_YJIT_OBJECT_SHAPE_COUNT,
                Core::Environment::YJIT.object_shape_count
              )
              gauge_if_not_nil(
                Core::Runtime::Ext::Metrics::METRIC_YJIT_OUTLINED_CODE_SIZE,
                Core::Environment::YJIT.outlined_code_size
              )
              gauge_if_not_nil(
                Core::Runtime::Ext::Metrics::METRIC_YJIT_YJIT_ALLOC_SIZE,
                Core::Environment::YJIT.yjit_alloc_size
              )
              gauge_if_not_nil(
                Core::Runtime::Ext::Metrics::METRIC_YJIT_RATIO_IN_YJIT,
                Core::Environment::YJIT.ratio_in_yjit
              )
            end
          end
        end
        # standard:enable Metrics/MethodLength
      end
    end
  end
end
