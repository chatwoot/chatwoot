# frozen_string_literal: true

require_relative 'core'
require_relative 'core/environment/variable_helpers'
require_relative 'core/utils/only_once'

module Datadog
  # Datadog Continuous Profiler implementation: https://docs.datadoghq.com/profiler/
  module Profiling
    def self.supported?
      unsupported_reason.nil?
    end

    def self.unsupported_reason
      # NOTE: Only the first matching reason is returned, so try to keep a nice order on reasons -- e.g. tell users
      # first that they can't use this on JRuby before telling them that something else failed

      native_library_compilation_skipped? || native_library_failed_to_load?
    end

    # Starts the profiler, if the profiler is supported by in
    # this runtime environment and if the profiler has been enabled
    # in configuration.
    #
    # @return [Boolean] `true` if the profiler has successfully started, otherwise `false`.
    # @public_api
    def self.start_if_enabled
      # If the profiler was not previously touched, getting the profiler instance triggers start as a side-effect
      # otherwise we get nil
      profiler = Datadog.send(:components).profiler
      # ...but we still try to start it BECAUSE if the process forks, the profiler will exist but may
      # not yet have been started in the fork
      profiler&.start
      !!profiler
    end

    # Returns an ever-increasing counter of the number of allocations observed by the profiler in this thread.
    #
    # Note 1: This counter may not start from zero on new threads. It should only be used to measure how many
    # allocations have happened between two calls to this API:
    # ```
    # allocations_before = Datadog::Profiling.allocation_count
    # do_some_work()
    # allocations_after = Datadog::Profiling.allocation_count
    # puts "Allocations during do_some_work: #{allocations_after - allocations_before}"
    # ```
    # (This is similar to some OS-based time representations.)
    #
    # Note 2: All fibers in the same thread will share the same counter values.
    # Note 3: This counter is not accurate when using the M:N scheduler.
    #
    # Only available when the profiler is running, and allocation-related features are not disabled via configuration.
    #
    # @return [Integer] number of allocations observed in the current thread.
    # @return [nil] when not available.
    # @public_api
    def self.allocation_count
      # This no-op implementation is used when profiling failed to load.
      # It gets replaced inside #replace_noop_allocation_count.
      nil
    end

    def self.enabled?
      profiler = Datadog.send(:components).profiler
      # Use .send(...) to avoid exposing the attr_reader as an API to the outside
      !!profiler&.send(:scheduler)&.running?
    end

    def self.wait_until_running(timeout_seconds: 5)
      profiler = Datadog.send(:components).profiler
      if profiler
        # Use .send(...) to avoid exposing the attr_reader as an API to the outside
        worker = profiler.send(:worker)
        worker.wait_until_running(timeout_seconds: timeout_seconds)
      else
        raise 'Profiler not enabled or available'
      end
    end

    private_class_method def self.replace_noop_allocation_count
      class << self
        remove_method :allocation_count
        def allocation_count
          Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_allocation_count
        end
      end
    end

    private_class_method def self.native_library_compilation_skipped?
      skipped_reason = try_reading_skipped_reason_file

      "Your datadog installation is missing support for the Continuous Profiler because #{skipped_reason}" if skipped_reason
    end

    private_class_method def self.try_reading_skipped_reason_file(file_api = File)
      # This file, if it exists, is recorded by extconf.rb during compilation of the native extension
      skipped_reason_file = "#{__dir__}/../../ext/datadog_profiling_native_extension/skipped_reason.txt"

      begin
        return unless file_api.exist?(skipped_reason_file)

        contents = file_api.read(skipped_reason_file).strip
        contents unless contents.empty?
      rescue
        # Do nothing
      end
    end

    private_class_method def self.native_library_failed_to_load?
      success, exception = try_loading_native_library

      unless success
        if exception
          'There was an error loading the profiling native extension due to ' \
          "'#{exception.class.name} #{exception.message}' at '#{Array(exception.backtrace).first}'"
        else
          'The profiling native extension did not load correctly. ' \
          'For help solving this issue, please contact Datadog support at <https://docs.datadoghq.com/help/>.' \
        end
      end
    end

    private_class_method def self.try_loading_native_library
      begin
        require_relative 'profiling/load_native_extension'

        success =
          defined?(Profiling::NativeExtension) && Profiling::NativeExtension.send(:native_working?)
        [success, nil]
      rescue StandardError, LoadError => e
        [false, e]
      end
    end

    # All requires for the profiler should be directly added here; and everything should be loaded eagerly.
    # (Currently there's a leftovers that need to be cleaned up, but we should avoid other exceptions.)
    #
    # All of the profiler should be loaded and ready to go when this method returns `true`.
    private_class_method def self.load_profiling
      return false unless supported?

      require_relative 'profiling/ext/dir_monkey_patches'
      require_relative 'profiling/collectors/info'
      require_relative 'profiling/collectors/code_provenance'
      require_relative 'profiling/collectors/cpu_and_wall_time_worker'
      require_relative 'profiling/collectors/dynamic_sampling_rate'
      require_relative 'profiling/collectors/idle_sampling_helper'
      require_relative 'profiling/collectors/stack'
      require_relative 'profiling/collectors/thread_context'
      require_relative 'profiling/stack_recorder'
      require_relative 'profiling/exporter'
      require_relative 'profiling/encoded_profile'
      require_relative 'profiling/flush'
      require_relative 'profiling/scheduler'
      require_relative 'profiling/tasks/setup'
      require_relative 'profiling/profiler'
      require_relative 'profiling/native_extension'
      require_relative 'profiling/tag_builder'
      require_relative 'profiling/http_transport'
      require_relative 'profiling/sequence_tracker'

      replace_noop_allocation_count

      true
    end

    load_profiling
  end
end
