# frozen_string_literal: true

require_relative 'agent_settings_resolver'
require_relative 'components_state'
require_relative 'ext'
require_relative '../diagnostics/environment_logger'
require_relative '../diagnostics/health'
require_relative '../logger'
require_relative '../runtime/metrics'
require_relative '../telemetry/component'
require_relative '../workers/runtime_metrics'
require_relative '../remote/component'
require_relative '../../tracing/component'
require_relative '../../profiling/component'
require_relative '../../appsec/component'
require_relative '../../di/component'
require_relative '../../error_tracking/component'
require_relative '../crashtracking/component'
require_relative '../environment/agent_info'
require_relative '../process_discovery'

module Datadog
  module Core
    module Configuration
      # Global components for the trace library.
      class Components
        class << self
          include Datadog::Tracing::Component

          def build_health_metrics(settings, logger, telemetry)
            settings = settings.health_metrics
            options = {enabled: settings.enabled}
            options[:statsd] = settings.statsd unless settings.statsd.nil?

            Core::Diagnostics::Health::Metrics.new(telemetry: telemetry, logger: logger, **options)
          end

          def build_logger(settings)
            logger = settings.logger.instance || Core::Logger.new($stdout)
            logger.level = settings.diagnostics.debug ? ::Logger::DEBUG : settings.logger.level

            logger
          end

          def build_runtime_metrics(settings, logger, telemetry)
            options = {enabled: settings.runtime_metrics.enabled}
            options[:statsd] = settings.runtime_metrics.statsd unless settings.runtime_metrics.statsd.nil?
            options[:services] = [settings.service] unless settings.service.nil?
            options[:experimental_runtime_id_enabled] = settings.runtime_metrics.experimental_runtime_id_enabled

            Core::Runtime::Metrics.new(logger: logger, telemetry: telemetry, **options)
          end

          def build_runtime_metrics_worker(settings, logger, telemetry)
            # NOTE: Should we just ignore building the worker if its not enabled?
            options = settings.runtime_metrics.opts.merge(
              enabled: settings.runtime_metrics.enabled,
              metrics: build_runtime_metrics(settings, logger, telemetry),
              logger: logger,
            )

            Core::Workers::RuntimeMetrics.new(telemetry: telemetry, **options)
          end

          def build_telemetry(settings, agent_settings, logger)
            Telemetry::Component.build(settings, agent_settings, logger)
          end

          def build_crashtracker(settings, agent_settings, logger:)
            return unless settings.crashtracking.enabled

            if (libdatadog_api_failure = Datadog::Core::LIBDATADOG_API_FAILURE)
              logger.debug("Cannot enable crashtracking: #{libdatadog_api_failure}")
              return
            end

            Datadog::Core::Crashtracking::Component.build(settings, agent_settings, logger: logger)
          end
        end

        include Datadog::Tracing::Component::InstanceMethods

        attr_reader \
          :health_metrics,
          :logger,
          :remote,
          :profiler,
          :runtime_metrics,
          :telemetry,
          :tracer,
          :crashtracker,
          :error_tracking,
          :dynamic_instrumentation,
          :appsec,
          :agent_info

        def initialize(settings)
          @logger = self.class.build_logger(settings)
          @environment_logger_extra = {}

          # This agent_settings is intended for use within Core. If you require
          # agent_settings within a product outside of core you should extend
          # the Core resolver from within your product/component's namespace.
          agent_settings = AgentSettingsResolver.call(settings, logger: @logger)

          # Exposes agent capability information for detection by any components
          @agent_info = Core::Environment::AgentInfo.new(agent_settings, logger: @logger)

          @telemetry = self.class.build_telemetry(settings, agent_settings, @logger)

          @remote = Remote::Component.build(settings, agent_settings, logger: @logger, telemetry: telemetry)
          @tracer = self.class.build_tracer(settings, agent_settings, logger: @logger)
          @crashtracker = self.class.build_crashtracker(settings, agent_settings, logger: @logger)

          @profiler, profiler_logger_extra = Datadog::Profiling::Component.build_profiler_component(
            settings: settings,
            agent_settings: agent_settings,
            optional_tracer: @tracer,
            logger: @logger,
          )
          @environment_logger_extra.merge!(profiler_logger_extra) if profiler_logger_extra

          @runtime_metrics = self.class.build_runtime_metrics_worker(settings, @logger, telemetry)
          @health_metrics = self.class.build_health_metrics(settings, @logger, telemetry)
          @appsec = Datadog::AppSec::Component.build_appsec_component(settings, telemetry: telemetry)
          @dynamic_instrumentation = Datadog::DI::Component.build(settings, agent_settings, @logger, telemetry: telemetry)
          @error_tracking = Datadog::ErrorTracking::Component.build(settings, @tracer, @logger)
          @environment_logger_extra[:dynamic_instrumentation_enabled] = !!@dynamic_instrumentation
          @process_discovery_fd = Core::ProcessDiscovery.get_and_store_metadata(settings, @logger)

          self.class.configure_tracing(settings)
        end

        # Starts up components
        def startup!(settings, old_state: nil)
          telemetry.start(old_state&.telemetry_enabled?)

          if settings.profiling.enabled
            if profiler
              profiler.start
            else
              # Display a warning for users who expected profiling to be enabled
              unsupported_reason = Profiling.unsupported_reason
              logger.warn("Profiling was requested but is not supported, profiling disabled: #{unsupported_reason}")
            end
          end

          if settings.remote.enabled && old_state&.remote_started?
            # The library was reconfigured and previously it already started
            # the remote component (i.e., it received at least one request
            # through the installed Rack middleware which started the remote).
            # If the new configuration also has remote enabled, start the
            # new remote right away.
            # remote should always be not nil here but steep doesn't know this.
            remote&.start
          end

          Core::Diagnostics::EnvironmentLogger.collect_and_log!(@environment_logger_extra)
        end

        # Shuts down all the components in use.
        # If it has another instance to compare to, it will compare
        # and avoid tearing down parts still in use.
        def shutdown!(replacement = nil)
          # Shutdown remote configuration
          remote&.shutdown!

          # Shutdown DI after remote, since remote config triggers DI operations.
          dynamic_instrumentation&.shutdown!

          # Decommission AppSec
          appsec&.shutdown!

          # Shutdown the old tracer, unless it's still being used.
          # (e.g. a custom tracer instance passed in.)
          tracer.shutdown! unless replacement && tracer.equal?(replacement.tracer)

          # Shutdown old profiler
          profiler&.shutdown!

          # Shutdown workers
          runtime_metrics.stop(true, close_metrics: false)

          # Shutdown the old metrics, unless they are still being used.
          # (e.g. custom Statsd instances.)
          #
          # TODO: This violates the encapsulation created by Runtime::Metrics and
          # Health::Metrics, by directly manipulating `statsd` and changing
          # it's lifecycle management.
          # If we need to directly have ownership of `statsd` lifecycle, we should
          # have direct ownership of it.
          old_statsd = [
            runtime_metrics.metrics.statsd,
            health_metrics.statsd
          ].compact.uniq

          new_statsd = if replacement
            [
              replacement.runtime_metrics.metrics.statsd,
              replacement.health_metrics.statsd
            ].compact.uniq
          else
            []
          end

          unused_statsd = (old_statsd - (old_statsd & new_statsd))
          unused_statsd.each(&:close)

          # enqueue closing event before stopping telemetry so it will be sent out on shutdown
          telemetry.emit_closing! unless replacement&.telemetry&.enabled
          telemetry.shutdown!

          @process_discovery_fd&.shutdown!
        end

        # Returns the current state of various components.
        def state
          ComponentsState.new(
            telemetry_enabled: telemetry.enabled,
            remote_started: remote&.started?,
          )
        end
      end
    end
  end
end
