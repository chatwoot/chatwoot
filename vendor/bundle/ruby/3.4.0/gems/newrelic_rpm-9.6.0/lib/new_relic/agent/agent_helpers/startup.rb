# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    module AgentHelpers
      module Startup
        # True if we have initialized and completed 'start'
        def started?
          @started
        end

        # Check whether we have already started, which is an error condition
        def already_started?
          if started?
            ::NewRelic::Agent.logger.error('Agent Started Already!')
            true
          end
        end

        # Logs a bunch of data and starts the agent, if needed
        def start
          return unless agent_should_start?

          log_startup
          check_config_and_start_agent
          log_version_and_pid

          events.subscribe(:initial_configuration_complete) do
            log_ignore_url_regexes
          end
        end

        # Sanity-check the agent configuration and start the agent,
        # setting up the worker thread and the exit handler to shut
        # down the agent
        def check_config_and_start_agent
          return unless monitoring? && has_correct_license_key?
          return if using_forking_dispatcher?

          setup_and_start_agent
        end

        # This is the shared method between the main agent startup and the
        # after_fork call restarting the thread in deferred dispatchers.
        #
        # Treatment of @started and env report is important to get right.
        def setup_and_start_agent(options = {})
          @started = true
          @harvester.mark_started

          unless in_resque_child_process?
            install_exit_handler
            environment_for_connect
            @harvest_samplers.load_samplers unless Agent.config[:disable_samplers]
          end

          connect_in_foreground if Agent.config[:sync_startup]
          start_worker_thread(options)
        end

        # Log startup information that we almost always want to know
        def log_startup
          log_environment
          log_dispatcher
          log_app_name
        end

        # Log the environment the app thinks it's running in.
        # Useful in debugging, as this is the key for config YAML lookups.
        def log_environment
          ::NewRelic::Agent.logger.info("Environment: #{NewRelic::Control.instance.env}")
        end

        # Logs the dispatcher to the log file to assist with
        # debugging. When no debugger is present, logs this fact to
        # assist with proper dispatcher detection
        def log_dispatcher
          dispatcher_name = Agent.config[:dispatcher].to_s

          if dispatcher_name.empty?
            ::NewRelic::Agent.logger.info('No known dispatcher detected.')
          else
            ::NewRelic::Agent.logger.info("Dispatcher: #{dispatcher_name}")
          end
        end

        def log_app_name
          ::NewRelic::Agent.logger.info("Application: #{Agent.config[:app_name].join(', ')}")
        end

        def log_ignore_url_regexes
          regexes = NewRelic::Agent.config[:'rules.ignore_url_regexes']

          unless regexes.empty?
            ::NewRelic::Agent.logger.info('Ignoring URLs that match the following regexes: ' \
              "#{regexes.map(&:inspect).join(', ')}.")
          end
        end

        # Classy logging of the agent version and the current pid,
        # so we can disambiguate processes in the log file and make
        # sure they're running a reasonable version
        def log_version_and_pid
          ::NewRelic::Agent.logger.debug("New Relic Ruby Agent #{NewRelic::VERSION::STRING} Initialized: pid = #{$$}")
        end

        # Logs the configured application names
        def app_name_configured?
          names = Agent.config[:app_name]
          return names.respond_to?(:any?) && names.any?
        end

        # Connecting in the foreground blocks further startup of the
        # agent until we have a connection - useful in cases where
        # you're trying to log a very-short-running process and want
        # to get statistics from before a server connection
        # (typically 20 seconds) exists
        def connect_in_foreground
          NewRelic::Agent.disable_all_tracing { connect(:keep_retrying => false) }
        end

        # Warn the user if they have configured their agent not to
        # send data, that way we can see this clearly in the log file
        def monitoring?
          if Agent.config[:monitor_mode]
            true
          else
            ::NewRelic::Agent.logger.warn('Agent configured not to send data in this environment.')
            false
          end
        end

        # Tell the user when the license key is missing so they can
        # fix it by adding it to the file
        def has_license_key?
          if Agent.config[:license_key] && Agent.config[:license_key].length > 0
            true
          else
            ::NewRelic::Agent.logger.warn('No license key found. ' +
              'This often means your newrelic.yml file was not found, or it lacks a section for the running ' \
              "environment, '#{NewRelic::Control.instance.env}'. You may also want to try linting your newrelic.yml " \
              'to ensure it is valid YML.')
            false
          end
        end

        # A correct license key exists and is of the proper length
        def has_correct_license_key?
          has_license_key? && correct_license_length
        end

        # A license key is an arbitrary 40 character string,
        # usually looks something like a SHA1 hash
        def correct_license_length
          key = Agent.config[:license_key]

          if key.length == 40
            true
          else
            ::NewRelic::Agent.logger.error("Invalid license key: #{key}")
            false
          end
        end

        # Check to see if the agent should start, returning +true+ if it should.
        def agent_should_start?
          return false if already_started? || disabled?

          if defer_for_delayed_job?
            ::NewRelic::Agent.logger.debug('Deferring startup for DelayedJob')
            return false
          end

          if defer_for_resque?
            ::NewRelic::Agent.logger.debug('Deferring startup for Resque in case it daemonizes')
            return false
          end

          unless app_name_configured?
            NewRelic::Agent.logger.error('No application name configured.',
              'The Agent cannot start without at least one. Please check your ',
              'newrelic.yml and ensure that it is valid and has at least one ',
              "value set for app_name in the #{NewRelic::Control.instance.env} ",
              'environment.')
            return false
          end

          return true
        end

        # The agent is disabled when it is not force enabled by the
        # 'agent_enabled' option (e.g. in a manual start), or
        # enabled normally through the configuration file
        def disabled?
          !Agent.config[:agent_enabled]
        end
      end
    end
  end
end
