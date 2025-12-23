# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/memory_logger'
require 'new_relic/agent/agent_logger'

module NewRelic
  class Control
    module PrivateInstanceMethods
      private

      def configure_high_security
        if security_settings_valid? && Agent.config[:high_security]
          Agent.logger.info('Installing high security configuration based on local configuration')
          Agent.config.replace_or_add_config(Agent::Configuration::HighSecuritySource.new(Agent.config))
        end
      end

      def log_yaml_source_failures(yaml_source)
        yaml_source.failures.each { |msg| stdout.puts Agent::AgentLogger.format_fatal_error(msg) }
      end

      def config_file_path
        @config_file_override || Agent.config[:config_path]
      end

      def create_logger(options)
        if ::NewRelic::Agent.logger.is_startup_logger?
          ::NewRelic::Agent.logger = NewRelic::Agent::AgentLogger.new(root, options.delete(:log))
        end
      end

      def init_instrumentation
        if !security_settings_valid?
          handle_invalid_security_settings
        elsif Agent.config[:agent_enabled] && !NewRelic::Agent.instance.started?
          start_agent
          install_instrumentation
        elsif !Agent.config[:agent_enabled]
          install_shim
        else
          DependencyDetection.detect!
        end
      end
    end
  end
end
