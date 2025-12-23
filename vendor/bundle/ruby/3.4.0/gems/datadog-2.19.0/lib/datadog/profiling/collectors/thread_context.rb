# frozen_string_literal: true

module Datadog
  module Profiling
    module Collectors
      # Used to trigger sampling of threads, based on external "events", such as:
      # * periodic timer for cpu-time and wall-time
      # * VM garbage collection events
      # * VM object allocation events
      # Triggering of this component (e.g. watching for the above "events") is implemented by
      # Collectors::CpuAndWallTimeWorker.
      # The stack collection itself is handled using the Datadog::Profiling::Collectors::Stack.
      # Almost all of this class is implemented as native code.
      #
      # Methods prefixed with _native_ are implemented in `collectors_thread_context.c`
      class ThreadContext
        def initialize(
          recorder:,
          max_frames:,
          tracer:,
          endpoint_collection_enabled:,
          timeline_enabled:,
          waiting_for_gvl_threshold_ns:,
          otel_context_enabled:,
          native_filenames_enabled:
        )
          tracer_context_key = safely_extract_context_key_from(tracer)
          self.class._native_initialize(
            self_instance: self,
            recorder: recorder,
            max_frames: max_frames,
            tracer_context_key: tracer_context_key,
            endpoint_collection_enabled: endpoint_collection_enabled,
            timeline_enabled: timeline_enabled,
            waiting_for_gvl_threshold_ns: waiting_for_gvl_threshold_ns,
            otel_context_enabled: otel_context_enabled,
            native_filenames_enabled: validate_native_filenames(native_filenames_enabled),
          )
        end

        def self.for_testing(
          recorder:,
          max_frames: 400,
          tracer: nil,
          endpoint_collection_enabled: false,
          timeline_enabled: false,
          waiting_for_gvl_threshold_ns: 10_000_000,
          otel_context_enabled: false,
          native_filenames_enabled: true,
          **options
        )
          new(
            recorder: recorder,
            max_frames: max_frames,
            tracer: tracer,
            endpoint_collection_enabled: endpoint_collection_enabled,
            timeline_enabled: timeline_enabled,
            waiting_for_gvl_threshold_ns: waiting_for_gvl_threshold_ns,
            otel_context_enabled: otel_context_enabled,
            native_filenames_enabled: native_filenames_enabled,
            **options,
          )
        end

        def inspect
          # Compose Ruby's default inspect with our custom inspect for the native parts
          result = super
          result[-1] = "#{self.class._native_inspect(self)}>"
          result
        end

        def reset_after_fork
          self.class._native_reset_after_fork(self)
        end

        private

        def safely_extract_context_key_from(tracer)
          return unless tracer

          provider = tracer.respond_to?(:provider) && tracer.provider

          return unless provider

          context = provider.instance_variable_get(:@context)
          context&.instance_variable_get(:@key)
        end

        def validate_native_filenames(native_filenames_enabled)
          if native_filenames_enabled && !Datadog::Profiling::Collectors::Stack._native_filenames_available?
            Datadog.logger.debug(
              "Native filenames are enabled, but the required dladdr API was not available. Disabling native filenames."
            )
            false
          else
            native_filenames_enabled
          end
        end
      end
    end
  end
end
