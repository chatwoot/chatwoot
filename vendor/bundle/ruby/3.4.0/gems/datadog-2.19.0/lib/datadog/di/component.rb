# frozen_string_literal: true

module Datadog
  module DI
    # Component for dynamic instrumentation.
    #
    # Only one instance of the Component should ever be active;
    # if configuration is changed, the old distance should be shut down
    # prior to the new instance being created.
    #
    # The Component instance stores all state related to DI, for example
    # which probes have been retrieved via remote config,
    # intalled tracepoints and so on. Component will clean up all
    # resources and installed tracepoints upon shutdown.
    class Component
      class << self
        def build(settings, agent_settings, logger, telemetry: nil)
          return unless settings.respond_to?(:dynamic_instrumentation) && settings.dynamic_instrumentation.enabled

          unless settings.respond_to?(:remote) && settings.remote.enabled
            logger.warn("di: dynamic instrumentation could not be enabled because Remote Configuration Management is not available. To enable Remote Configuration, see https://docs.datadoghq.com/agent/remote_config")
            return
          end

          return unless environment_supported?(settings, logger)

          new(settings, agent_settings, logger, code_tracker: DI.code_tracker, telemetry: telemetry).tap do |component|
            DI.add_current_component(component)
          end
        end

        def build!(settings, agent_settings, logger, telemetry: nil)
          unless settings.respond_to?(:dynamic_instrumentation) && settings.dynamic_instrumentation.enabled
            raise "Requested DI component but DI is not enabled in settings"
          end

          unless settings.respond_to?(:remote) && settings.remote.enabled
            raise "Requested DI component but remote config is not enabled in settings"
          end

          unless environment_supported?(settings, logger)
            raise "DI does not support the environment (development or Ruby version too low or not MRI)"
          end

          new(settings, agent_settings, logger, code_tracker: DI.code_tracker, telemetry: telemetry)
        end

        # Checks whether the runtime environment is supported by
        # dynamic instrumentation. Currently we only require that, if Rails
        # is used, that Rails environment is not development because
        # DI does not currently support code unloading and reloading.
        def environment_supported?(settings, logger)
          # TODO add tests?
          unless settings.dynamic_instrumentation.internal.development
            if Datadog::Core::Environment::Execution.development?
              logger.warn("di: development environment detected; not enabling dynamic instrumentation")
              return false
            end
          end
          if RUBY_ENGINE != 'ruby'
            logger.warn("di: cannot enable dynamic instrumentation: MRI is required, but running on #{RUBY_ENGINE}")
            return false
          end
          if RUBY_VERSION < '2.6'
            logger.warn("di: cannot enable dynamic instrumentation: Ruby 2.6+ is required, but running on #{RUBY_VERSION}")
            return false
          end
          true
        end
      end

      def initialize(settings, agent_settings, logger, code_tracker: nil, telemetry: nil)
        @settings = settings
        @agent_settings = agent_settings
        logger = DI::Logger.new(settings, logger)
        @logger = logger
        @telemetry = telemetry
        @code_tracker = code_tracker
        @redactor = Redactor.new(settings)
        @serializer = Serializer.new(settings, redactor, telemetry: telemetry)
        @instrumenter = Instrumenter.new(settings, serializer, logger, code_tracker: code_tracker, telemetry: telemetry)
        @probe_notifier_worker = ProbeNotifierWorker.new(settings, logger, agent_settings: agent_settings, telemetry: telemetry)
        @probe_notification_builder = ProbeNotificationBuilder.new(settings, serializer)
        @probe_manager = ProbeManager.new(settings, instrumenter, probe_notification_builder, probe_notifier_worker, logger, telemetry: telemetry)
        probe_notifier_worker.start
      end

      attr_reader :settings
      attr_reader :agent_settings
      attr_reader :logger
      attr_reader :telemetry
      attr_reader :code_tracker
      attr_reader :instrumenter
      attr_reader :probe_notifier_worker
      attr_reader :probe_notification_builder
      attr_reader :probe_manager
      attr_reader :redactor
      attr_reader :serializer

      # Shuts down dynamic instrumentation.
      #
      # Removes all code hooks and stops background threads.
      #
      # Does not clear out the code tracker, because it's only populated
      # by code when code is compiled and therefore, if the code tracker
      # was replaced by a new instance, the new instance of it wouldn't have
      # any of the already loaded code tracked.
      def shutdown!(replacement = nil)
        DI.remove_current_component(self)

        probe_manager.clear_hooks
        probe_manager.close
        probe_notifier_worker.stop
      end
    end
  end
end
