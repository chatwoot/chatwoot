# frozen_string_literal: true

require_relative '../runtime/metrics'

require_relative '../worker'
require_relative 'async'
require_relative 'polling'

module Datadog
  module Core
    module Workers
      # Emits runtime metrics asynchronously on a timed loop
      class RuntimeMetrics < Worker
        include Workers::Polling

        # In seconds
        DEFAULT_FLUSH_INTERVAL = 10
        DEFAULT_BACK_OFF_MAX = 30

        attr_reader \
          :metrics

        def initialize(telemetry:, **options)
          @metrics = options.fetch(:metrics) { Core::Runtime::Metrics.new(logger: options[:logger], telemetry: telemetry) }

          # Workers::Async::Thread settings
          self.fork_policy = options.fetch(:fork_policy, Workers::Async::Thread::FORK_POLICY_STOP)

          # Workers::IntervalLoop settings
          self.loop_base_interval = options.fetch(:interval, DEFAULT_FLUSH_INTERVAL)
          self.loop_back_off_ratio = options[:back_off_ratio] if options.key?(:back_off_ratio)
          self.loop_back_off_max = options.fetch(:back_off_max, DEFAULT_BACK_OFF_MAX)

          self.enabled = options.fetch(:enabled, false)
        end

        def perform
          metrics.flush
          true
        end

        def register_service(service)
          # Start the worker
          metrics.register_service(service).tap { perform }
        end

        # TODO: `close_metrics` is only needed because
        # Datadog::Core::Configuration::Components directly manipulates
        # the lifecycle of Runtime::Metrics.statsd instances.
        # This should be avoided, as it prevents this class from
        # ensuring correct resource decommission of its internal
        # dependencies.
        def stop(*args, close_metrics: true)
          self.enabled = false
          result = super(*args)
          @metrics.close if close_metrics
          result
        end
      end
    end
  end
end
