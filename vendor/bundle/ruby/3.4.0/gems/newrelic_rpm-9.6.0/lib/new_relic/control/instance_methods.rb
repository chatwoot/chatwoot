# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/null_logger'
require 'new_relic/agent/memory_logger'
require 'new_relic/agent/agent_logger'

require_relative 'private_instance_methods'

module NewRelic
  class Control
    # Contains methods that relate to the runtime usage of the control
    # object. Note that these are subject to override in the
    # NewRelic::Control::Framework classes that are actually instantiated
    module InstanceMethods
      include PrivateInstanceMethods
      # The env is the setting used to identify which section of the newrelic.yml
      # to load.  This defaults to a framework specific value, such as ENV['RAILS_ENV']
      # but can be overridden as long as you set it before calling #init_plugin
      attr_writer :env

      # The local environment contains all the information we report
      # to the server about what kind of application this is, what
      # gems and plugins it uses, and many other kinds of
      # machine-dependent information useful in debugging
      attr_reader :local_env

      # Initialize the plugin/gem and start the agent.  This does the
      # necessary configuration based on the framework environment and
      # determines whether or not to start the agent.  If the agent is
      # not going to be started then it loads the agent shim which has
      # stubs for all the external api.
      #
      # This may be invoked multiple times, as long as you don't attempt
      # to uninstall the agent after it has been started.
      #
      # If the plugin is initialized and it determines that the agent is
      # not enabled, it will skip starting it and install the shim.  But
      # if you later call this with <tt>:agent_enabled => true</tt>,
      # then it will install the real agent and start it.
      #
      # What determines whether the agent is launched is the result of
      # calling agent_enabled?  This will indicate whether the
      # instrumentation should/will be installed.  If we're in a mode
      # where tracers are not installed then we should not start the
      # agent.
      #
      # Subclasses are not allowed to override, but must implement
      # init_config({}) which is called one or more times.
      #
      def init_plugin(options = {})
        env = determine_env(options)

        configure_agent(env, options)

        # Be sure to only create once! RUBY-1020
        create_logger(options)

        # Merge the stringified options into the config as overrides:
        environment_name = options.delete(:env) and self.env = environment_name

        NewRelic::Agent::PipeChannelManager.listener.start if options.delete(:start_channel_listener)

        # An artifact of earlier implementation, we put both #add_method_tracer and #trace_execution
        # methods in the module methods.
        # Rails applications load the next two lines before any other initializers are run
        unless defined?(Rails::VERSION) && ENV['NEW_RELIC_DEFER_RAILS_INITIALIZATION']
          Module.send(:include, NewRelic::Agent::MethodTracer::ClassMethods)
          Module.send(:include, NewRelic::Agent::MethodTracer)
        end

        init_config(options)
        NewRelic::Agent.agent = NewRelic::Agent::Agent.instance
        init_instrumentation
      end

      def determine_env(options)
        env = options[:env] || self.env
        env = env.to_s

        if @started_in_env && @started_in_env != env
          Agent.logger.error("Attempted to start agent in #{env.inspect} environment, but agent was already running " \
            "in #{@started_in_env.inspect}", "The agent will continue running in #{@started_in_env.inspect}. To " \
            'alter this, ensure the desired environment is set before the agent starts.')
        else
          Agent.logger.info("Starting the New Relic agent version #{NewRelic::VERSION::STRING} in #{env.inspect} " \
            'environment.', 'To prevent agent startup add a NEW_RELIC_AGENT_ENABLED=false environment variable or ' \
            "modify the #{env.inspect} section of your newrelic.yml.")
        end

        env
      end

      def configure_agent(env, options)
        manual = Agent::Configuration::ManualSource.new(options)
        Agent.config.replace_or_add_config(manual)
        yaml_source = Agent::Configuration::YamlSource.new(config_file_path, env)
        log_yaml_source_failures(yaml_source) if yaml_source.failed?
        Agent.config.replace_or_add_config(yaml_source)
        configure_high_security
      end

      def security_settings_valid?
        !Agent.config[:high_security] || Agent.config[:security_policies_token].empty?
      end

      def handle_invalid_security_settings
        NewRelic::Agent.logger.error('Security Policies and High Security Mode cannot both be present in the agent ' \
          'configuration. If Security Policies have been set for your account, please ensure the ' \
          'security_policies_token is set but high_security is disabled (default).')
        install_shim
      end

      # Install the real agent into the Agent module, and issue the start command.
      def start_agent
        @started_in_env = self.env
        NewRelic::Agent.agent.start
      end

      def app
        Agent.config[:framework]
      end

      def framework
        Agent.config[:framework]
      end

      # for backward compatibility with the old config interface
      def [](key)
        NewRelic::Agent.config[key.to_sym]
      end

      def settings
        NewRelic::Agent.config.to_collector_hash
      end

      def dispatcher
        NewRelic::Agent.config[:dispatcher]
      end

      # Delegates to the class method newrelic_root, implemented by
      # each subclass
      def newrelic_root
        self.class.newrelic_root
      end

      protected

      def initialize(local_env, config_file_override = nil)
        @install_lock = Mutex.new
        @local_env = local_env
        @started_in_env = nil
        @instrumented = nil
        @instrumentation_files = []
        @config_file_override = config_file_override
      end

      def root
        '.'
      end

      def stdout
        STDOUT
      end
    end
    include InstanceMethods
  end
end
