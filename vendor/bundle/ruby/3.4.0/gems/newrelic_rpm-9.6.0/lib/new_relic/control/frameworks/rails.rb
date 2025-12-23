# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/control/frameworks/ruby'
module NewRelic
  class Control
    module Frameworks
      # Control subclass instantiated when Rails is detected.  Contains
      # Rails specific configuration, instrumentation, environment values,
      # etc.
      class Rails < NewRelic::Control::Frameworks::Ruby
        BROWSER_MONITORING_INSTALLED_SINGLETON = NewRelic::Agent.config
        BROWSER_MONITORING_INSTALLED_VARIABLE = :@browser_monitoring_installed

        def env
          @env ||= (ENV['NEW_RELIC_ENV'] || RAILS_ENV.dup)
        end

        # Rails can return an empty string from this method, causing
        # the agent not to start even when it is properly in a rails 3
        # application, so we test the value to make sure it actually
        # has contents, and bail to the parent class if it is empty.
        def root
          root = rails_root.to_s
          if !root.empty?
            root
          else
            super
          end
        end

        def rails_root
          RAILS_ROOT if defined?(RAILS_ROOT)
        end

        def rails_config
          if defined?(::Rails) && ::Rails.respond_to?(:configuration)
            ::Rails.configuration
          else
            @config
          end
        end

        # In versions of Rails prior to 2.0, the rails config was only available to
        # the init.rb, so it had to be passed on from there.  This is a best effort to
        # find a config and use that.
        def init_config(options = {})
          @config = options[:config]
          install_dependency_detection
          install_browser_monitoring_and_agent_hooks
        rescue => e
          ::NewRelic::Agent.logger.error('Failure during init_config for Rails. Is Rails required in a non-Rails ' \
                                         'app? Set NEW_RELIC_FRAMEWORK=ruby to avoid this message. The Ruby agent ' \
                                         'will continue running, but Rails-specific features may be missing. ' \
                                         "#{e.class} - #{e.message}")
        end

        def install_dependency_detection
          return unless rails_config && ::Rails.configuration.respond_to?(:after_initialize)

          rails_config.after_initialize do
            # This will insure we load all the instrumentation as late as
            # possible. If the agent is not enabled, it will load a limited
            # amount of instrumentation.
            DependencyDetection.detect!
          end
        end

        def install_browser_monitoring_and_agent_hooks
          return unless rails_config

          if !Agent.config[:agent_enabled]
            # Might not be running if it does not think mongrel, thin,
            # passenger, etc. is running, if it thinks it's a rake task, or
            # if the agent_enabled is false.
            ::NewRelic::Agent.logger.info('New Relic Agent not running. Skipping browser monitoring and agent hooks.')
          else
            install_browser_monitoring(rails_config)
            install_agent_hooks(rails_config)
          end
        end

        def install_agent_hooks(config)
          return if defined?(@agent_hooks_installed) && @agent_hooks_installed

          @agent_hooks_installed = true
          return if config.nil? || !config.respond_to?(:middleware)

          begin
            require 'new_relic/rack/agent_hooks'
            return unless NewRelic::Rack::AgentHooks.needed?

            config.middleware.use(NewRelic::Rack::AgentHooks)
            ::NewRelic::Agent.logger.debug('Installed New Relic Agent Hooks middleware')
          rescue => e
            ::NewRelic::Agent.logger.warn('Error installing New Relic Agent Hooks middleware', e)
          end
        end

        def install_browser_monitoring(config)
          @install_lock.synchronize do
            return if browser_agent_already_installed?

            mark_browser_agent_as_installed
            return if config.nil? || !config.respond_to?(:middleware) || !Agent.config[:'browser_monitoring.auto_instrument']

            begin
              require 'new_relic/rack/browser_monitoring'
              config.middleware.use(NewRelic::Rack::BrowserMonitoring)
              ::NewRelic::Agent.logger.debug('Installed New Relic Browser Monitoring middleware')
            rescue => e
              ::NewRelic::Agent.logger.warn('Error installing New Relic Browser Monitoring middleware', e)
            end
          end
        end

        def browser_agent_already_installed?
          BROWSER_MONITORING_INSTALLED_SINGLETON.instance_variable_defined?(BROWSER_MONITORING_INSTALLED_VARIABLE) &&
            BROWSER_MONITORING_INSTALLED_SINGLETON.instance_variable_get(BROWSER_MONITORING_INSTALLED_VARIABLE)
        end

        def mark_browser_agent_as_installed
          BROWSER_MONITORING_INSTALLED_SINGLETON.instance_variable_set(BROWSER_MONITORING_INSTALLED_VARIABLE, true)
        end

        def rails_version
          @rails_version ||= Gem::Version.new(::Rails::VERSION::STRING)
        end

        protected

        def rails_vendor_root
          File.join(root, 'vendor', 'rails')
        end

        def install_shim
          super
          require 'new_relic/agent/instrumentation/controller_instrumentation'
          if ActiveSupport.respond_to?(:on_load) # rails 3+
            ActiveSupport.on_load(:action_controller) { include NewRelic::Agent::Instrumentation::ControllerInstrumentation::Shim }
          else
            ActionController::Base.class_eval { include NewRelic::Agent::Instrumentation::ControllerInstrumentation::Shim }
          end
        end
      end
    end
  end
end
