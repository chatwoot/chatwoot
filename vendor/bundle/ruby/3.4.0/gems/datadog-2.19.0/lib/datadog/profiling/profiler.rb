# frozen_string_literal: true

module Datadog
  module Profiling
    # Profiling entry point, which coordinates the worker and scheduler threads
    class Profiler
      include Datadog::Core::Utils::Forking

      private

      attr_reader :worker, :scheduler

      public

      def initialize(worker:, scheduler:)
        @worker = worker
        @scheduler = scheduler
      end

      def start
        after_fork! do
          worker.reset_after_fork
          scheduler.reset_after_fork
        end

        worker.start(on_failure_proc: proc { component_failed(:worker) })
        scheduler.start(on_failure_proc: proc { component_failed(:scheduler) })
      end

      def shutdown!
        Datadog.logger.debug("Shutting down profiler")

        stop_worker
        stop_scheduler
      end

      private

      def stop_worker
        worker.stop
      end

      def stop_scheduler
        scheduler.enabled = false
        scheduler.stop(true)
      end

      def component_failed(failed_component)
        Datadog.logger.warn(
          "Detected issue with profiler (#{failed_component} component), stopping profiling. " \
          "See previous log messages for details."
        )
        Datadog::Core::Telemetry::Logger
          .error("Detected issue with profiler (#{failed_component} component), stopping profiling")

        # We explicitly not stop the crash tracker in this situation, under the assumption that, if a component failed,
        # we're operating in a degraded state and crash tracking may still be helpful.

        if failed_component == :worker
          scheduler.mark_profiler_failed
          stop_scheduler
        elsif failed_component == :scheduler
          stop_worker
        else
          raise ArgumentError, "Unexpected failed_component: #{failed_component.inspect}"
        end
      end
    end
  end
end
