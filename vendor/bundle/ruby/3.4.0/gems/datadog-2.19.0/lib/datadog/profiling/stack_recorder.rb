# frozen_string_literal: true

require_relative "../core/telemetry/logger"

module Datadog
  module Profiling
    # Stores stack samples in a native libdatadog data structure and expose Ruby-level serialization APIs
    # Note that `record_sample` is only accessible from native code.
    # Methods prefixed with _native_ are implemented in `stack_recorder.c`
    class StackRecorder
      def initialize(
        cpu_time_enabled:,
        alloc_samples_enabled:,
        heap_samples_enabled:,
        heap_size_enabled:,
        heap_sample_every:,
        timeline_enabled:,
        heap_clean_after_gc_enabled:
      )
        # This mutex works in addition to the fancy C-level mutexes we have in the native side (see the docs there).
        # It prevents multiple Ruby threads calling serialize at the same time -- something like
        # `10.times { Thread.new { stack_recorder.serialize } }`.
        # This isn't something we expect to happen normally, but because it would break the assumptions of the
        # C-level mutexes (that there is a single serializer thread), we add it here as an extra safeguard against it
        # accidentally happening.
        @no_concurrent_serialize_mutex = Mutex.new

        self.class._native_initialize(
          self_instance: self,
          cpu_time_enabled: cpu_time_enabled,
          alloc_samples_enabled: alloc_samples_enabled,
          heap_samples_enabled: heap_samples_enabled,
          heap_size_enabled: heap_size_enabled,
          heap_sample_every: heap_sample_every,
          timeline_enabled: timeline_enabled,
          heap_clean_after_gc_enabled: heap_clean_after_gc_enabled,
        )
      end

      def self.for_testing(
        cpu_time_enabled: true,
        alloc_samples_enabled: false,
        heap_samples_enabled: false,
        heap_size_enabled: false,
        heap_sample_every: 1,
        timeline_enabled: false,
        heap_clean_after_gc_enabled: true,
        **options
      )
        new(
          cpu_time_enabled: cpu_time_enabled,
          alloc_samples_enabled: alloc_samples_enabled,
          heap_samples_enabled: heap_samples_enabled,
          heap_size_enabled: heap_size_enabled,
          heap_sample_every: heap_sample_every,
          timeline_enabled: timeline_enabled,
          heap_clean_after_gc_enabled: heap_clean_after_gc_enabled,
          **options,
        )
      end

      def serialize
        status, result = @no_concurrent_serialize_mutex.synchronize { self.class._native_serialize(self) }

        if status == :ok
          start, finish, encoded_profile, profile_stats = result

          Datadog.logger.debug { "Encoded profile covering #{start.iso8601} to #{finish.iso8601}" }

          [start, finish, encoded_profile, profile_stats]
        else
          error_message = result

          Datadog.logger.warn("Failed to serialize profiling data: #{error_message}")
          Datadog::Core::Telemetry::Logger.error("Failed to serialize profiling data (#{error_message})")

          nil
        end
      end

      def serialize!
        status, result = @no_concurrent_serialize_mutex.synchronize { self.class._native_serialize(self) }

        if status == :ok
          _start, _finish, encoded_profile = result

          encoded_profile
        else
          error_message = result

          raise("Failed to serialize profiling data: #{error_message}")
        end
      end

      def reset_after_fork
        self.class._native_reset_after_fork(self)
      end

      def stats
        self.class._native_stats(self)
      end
    end
  end
end
