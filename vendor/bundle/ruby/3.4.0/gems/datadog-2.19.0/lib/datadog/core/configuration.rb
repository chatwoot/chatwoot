# frozen_string_literal: true

require_relative 'configuration/components'
require_relative 'configuration/settings'
require_relative 'telemetry/emitter'
require_relative 'logger'
require_relative 'pin'

module Datadog
  module Core
    # Configuration provides a unique access point for configurations
    module Configuration
      # Used to ensure that @components initialization/reconfiguration is performed one-at-a-time, by a single thread.
      #
      # This is important because components can end up being accessed from multiple application threads (for instance on
      # a threaded webserver), and we don't want their initialization to clash (for instance, starting two profilers...).
      #
      # Note that a Mutex **IS NOT** reentrant: the same thread cannot grab the same Mutex more than once.
      # This means below we are careful not to nest calls to methods that would trigger initialization and grab the lock.
      #
      # Every method that directly or indirectly mutates @components should be holding the lock (through
      # #safely_synchronize) while doing so.
      COMPONENTS_WRITE_LOCK = Mutex.new
      private_constant :COMPONENTS_WRITE_LOCK

      # We use a separate lock when reading the @components, so that they continue to be accessible during reconfiguration.
      # This was needed because we ran into several issues where we still needed to read the old
      # components while the COMPONENTS_WRITE_LOCK was being held (see https://github.com/DataDog/dd-trace-rb/pull/1387
      # and https://github.com/DataDog/dd-trace-rb/pull/1373#issuecomment-799593022 ).
      #
      # Technically on MRI we could get away without this lock, but on non-MRI Rubies, we may run into issues because
      # we fall into the "UnsafeDCLFactory" case of https://shipilev.net/blog/2014/safe-public-construction/ .
      # Specifically, on JRuby reads from the @components do NOT have volatile semantics, and on TruffleRuby they do
      # BUT just as an implementation detail, see https://github.com/jruby/jruby/wiki/Concurrency-in-jruby#volatility and
      # https://github.com/DataDog/dd-trace-rb/pull/1329#issuecomment-776750377 .
      # Concurrency is hard.
      COMPONENTS_READ_LOCK = Mutex.new
      private_constant :COMPONENTS_READ_LOCK

      attr_writer :configuration

      # Current Datadog configuration.
      #
      # Access to non-global configuration will raise an error.
      #
      # To modify the configuration, use {.configure}.
      #
      # @return [Datadog::Core::Configuration::Settings]
      # @!attribute [r] configuration

      # @public_api
      def configuration
        @configuration ||= Settings.new
      end

      # Apply global configuration changes to `Datadog`. An example of a {.configure} call:
      #
      # ```
      # Datadog.configure do |c|
      #   c.service = 'my-service'
      #   c.env = 'staging'
      #   # c.diagnostics.debug = true # Enables debug output
      # end
      # ```
      #
      # See {Datadog::Core::Configuration::Settings} for all available options, defaults, and
      # available environment variables for configuration.
      #
      # Only permits access to global configuration settings; others will raise an error.
      # If you wish to configure a setting for a specific Datadog component (e.g. Tracing),
      # use the corresponding `Datadog::COMPONENT.configure` method instead.
      #
      # Because many configuration changes require restarting internal components,
      # invoking {.configure} is the only safe way to change `Datadog` configuration.
      #
      # Successive calls to {.configure} maintain the previous configuration values:
      # configuration is additive between {.configure} calls.
      #
      # The yielded configuration `c` comes pre-populated from environment variables, if
      # any are applicable.
      #
      # @yieldparam [Datadog::Core::Configuration::Settings] c the mutable configuration object
      def configure
        configuration = self.configuration
        yield(configuration)

        safely_synchronize do |write_components|
          write_components.call(
            if components?
              replace_components!(configuration, @components)
            else
              build_components(configuration)
            end
          )
        end

        configuration
      end

      # Apply configuration changes only to a specific Ruby object.
      #
      # Certain integrations or Datadog features may use these
      # settings to customize behavior for this object.
      #
      # An example of a {.configure_onto} call:
      #
      # ```
      # client = Net::HTTP.new(host, port)
      # Datadog.configure_onto(client, service_name: 'api-requests', split_by_domain: true)
      # ```
      #
      # In this example, it will configure the `client` object with custom options
      # `service_name: 'api-requests', split_by_domain: true`. The `Net::HTTP` integration
      # will then use these customized options when the `client` is used, whereas other
      # clients will use the `service_name: 'http-requests'` configuration provided to the
      # `Datadog.configure` call block.
      #
      # {.configure_onto} is used to separate cases where spans generated by certain objects
      # require exceptional options.
      #
      # The configuration keyword arguments provided should match well known options defined
      # in the integration or feature that would use them.
      #
      # For example, for `Datadog.configure_onto(redis_client, **opts)`, `opts` can be
      # any of the options in the Redis {Datadog::Tracing::Contrib::Redis::Configuration::Settings} class.
      #
      # @param [Object] target the object to receive configuration options
      # @param [Hash] opts keyword arguments respective to the integration this object belongs to
      # @public_api
      def configure_onto(target, **opts)
        Pin.set_on(target, **opts)
      end

      # Get configuration changes applied only to a specific Ruby object, via {.configure_onto}.
      # An example of an object with specific configuration:
      #
      # ```
      # client = Net::HTTP.new(host, port)
      # Datadog.configure_onto(client, service_name: 'api-requests', split_by_domain: true)
      # config = Datadog.configuration_for(client)
      # config[:service_name] # => 'api-requests'
      # config[:split_by_domain] # => true
      # ```
      #
      # @param [Object] target the object to receive configuration options
      # @param [Object] option an option to retrieve from the object configuration
      # @public_api
      def configuration_for(target, option = nil)
        pin = Pin.get_from(target)
        return pin unless option

        pin[option] if pin
      end

      # Internal {Datadog::Statsd} metrics collection.
      #
      # The list of metrics collected can be found in {Datadog::Core::Diagnostics::Ext::Health::Metrics}.
      # @public_api
      def health_metrics
        components.health_metrics
      end

      def logger
        # avoid initializing components if they didn't already exist
        current_components = components(allow_initialization: false)

        if current_components
          @temp_logger = nil
          current_components.logger
        else
          logger_without_components
        end
      end

      def config_init_logger
        configuration? ? logger : logger_without_configuration
      end

      # Gracefully shuts down all components.
      #
      # Components will still respond to method calls as usual,
      # but might not internally perform their work after shutdown.
      #
      # This avoids errors being raised across the host application
      # during shutdown, while allowing for graceful decommission of resources.
      #
      # Components won't be automatically reinitialized after a shutdown.
      def shutdown!
        safely_synchronize do
          @components.shutdown! if components?
        end
      end

      protected

      def components(allow_initialization: true)
        current_components = COMPONENTS_READ_LOCK.synchronize { defined?(@components) && @components }
        return current_components if current_components || !allow_initialization

        safely_synchronize do |write_components|
          if defined?(@components) && @components
            @components
          else
            write_components.call(build_components(configuration))
          end
        end
      end

      private

      # Gracefully shuts down Datadog components and disposes of component references,
      # allowing execution to start anew.
      #
      # In contrast with +#shutdown!+, components will be automatically
      # reinitialized after a reset.
      #
      # Used internally to ensure a clean environment between test runs.
      def reset!
        safely_synchronize do |write_components|
          if components?
            @components.shutdown!
            @temp_logger = nil # Reset to ensure instance and log level are reset for next run
          end

          write_components.call(nil)
          configuration.reset!
        end
      end

      def safely_synchronize
        # Writes to @components should only happen through this proc. Because this proc is only accessible to callers of
        # safely_synchronize, this forces all writers to go through this method.
        write_components = proc do |new_value|
          COMPONENTS_READ_LOCK.synchronize { @components = new_value }
        end

        COMPONENTS_WRITE_LOCK.synchronize do
          yield write_components
        rescue ThreadError => e
          logger_without_components.error(
            'Detected deadlock during datadog initialization. ' \
            'Please report this at https://github.com/datadog/dd-trace-rb/blob/master/CONTRIBUTING.md#found-a-bug' \
            "\n\tSource:\n\t#{Array(e.backtrace).join("\n\t")}"
          )
          nil
        end
      end

      def configuration?
        (defined?(@configuration) && @configuration) != nil
      end

      def components?
        # This does not need to grab the COMPONENTS_READ_LOCK because it's not returning the components
        (defined?(@components) && @components) != nil
      end

      def build_components(settings)
        components = Components.new(settings)
        components.startup!(settings)
        components
      end

      def replace_components!(settings, old)
        components = Components.new(settings)

        # Carry over state from existing components to the new ones.
        # Currently:
        # 1. If we already started the remote component (which
        #    happens after a request goes through installed Rack middleware),
        #    we will start the new remote component as well.
        # 2. If telemetry has been enabled and is enabled in the new
        #    component tree, we send AppConfigurationChange event instead
        #    of AppStarted event.
        old_state = old.state

        old.shutdown!(components)
        components.startup!(settings, old_state: old_state)
        components
      end

      def logger_without_components
        # Use default logger without initializing components.
        # This enables logging during initialization, otherwise we'd run into deadlocks.

        @temp_logger ||= begin
          logger = configuration.logger.instance || Core::Logger.new($stdout)
          logger.level = configuration.diagnostics.debug ? ::Logger::DEBUG : configuration.logger.level
          logger
        end
      end

      def logger_without_configuration
        # There's rare cases where we need to use logger during configuration initialization,
        # such as reading stable config. In this case we cannot access configuration.

        @temp_config_logger ||= begin
          debug_env_value = ENV[Ext::Diagnostics::ENV_DEBUG_ENABLED]&.strip&.downcase
          debug_value = debug_env_value == 'true' || debug_env_value == '1'

          logger = Core::Logger.new($stdout)
          # We cannot access config and the default level is INFO, so we need to set the level manually
          logger.level = debug_value ? ::Logger::DEBUG : ::Logger::INFO
          logger
        end
      end

      # Called from our at_exit hook whenever there was a pending Interrupt exception (e.g. typically due to ctrl+c)
      # to print a nice message whenever we're taking a bit longer than usual to finish the process.
      def handle_interrupt_shutdown!
        logger = Datadog.logger
        shutdown_thread = Thread.new { shutdown! }
        shutdown_thread.name = Datadog::Core::Configuration.name

        print_message_treshold_seconds = 0.2

        slow_shutdown = shutdown_thread.join(print_message_treshold_seconds).nil?

        if slow_shutdown
          logger.info 'Reporting remaining data... Press ctrl+c to exit immediately.'
          shutdown_thread.join
        end

        nil
      end
    end
  end
end
