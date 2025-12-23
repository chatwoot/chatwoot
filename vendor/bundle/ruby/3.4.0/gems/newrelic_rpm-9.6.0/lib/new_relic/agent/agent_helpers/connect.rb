# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    module AgentHelpers
      # This module is an artifact of a refactoring of the connect
      # method - all of its methods are used in that context, so it
      # can be refactored at will. It should be fully tested
      module Connect
        # number of attempts we've made to contact the server
        attr_accessor :connect_attempts

        # Disconnect just sets the connect state to disconnected, preventing
        # further retries.
        def disconnect
          @connect_state = :disconnected
          true
        end

        def connected?
          @connect_state == :connected
        end

        def disconnected?
          @connect_state == :disconnected
        end

        # Don't connect if we're already connected, or if we tried to connect
        # and were rejected with prejudice because of a license issue, unless
        # we're forced to by force_reconnect.
        def should_connect?(force = false)
          force || (!connected? && !disconnected?)
        end

        # Per the spec at
        # /agents/agent-specs/Collector-Response-Handling.md, retry
        # connections after a specific backoff sequence to prevent
        # hammering the server.
        def connect_retry_period
          NewRelic::CONNECT_RETRY_PERIODS[connect_attempts] || NewRelic::MAX_RETRY_PERIOD
        end

        def note_connect_failure
          self.connect_attempts += 1
        end

        # When we have a problem connecting to the server, we need
        # to tell the user what happened, since this is not an error
        # we can handle gracefully.
        def log_error(error)
          ::NewRelic::Agent.logger.error("Error establishing connection with New Relic Service at #{control.server}:",
            error)
        end

        # When the server sends us an error with the license key, we
        # want to tell the user that something went wrong, and let
        # them know where to go to get a valid license key
        #
        # After this runs, it disconnects the agent so that it will
        # no longer try to connect to the server, saving the
        # application and the server load
        def handle_license_error(error)
          ::NewRelic::Agent.logger.error( \
            error.message, \
            'Visit NewRelic.com to obtain a valid license key, or to upgrade your account.'
          )
          disconnect
        end

        def handle_unrecoverable_agent_error(error)
          ::NewRelic::Agent.logger.error(error.message)
          disconnect
          shutdown
        end

        # Checks whether we should send environment info, and if so,
        # returns the snapshot from the local environment.
        # Generating the EnvironmentReport has the potential to trigger
        # require calls in Rails environments, so this method should only
        # be called synchronously from on the main thread.
        def environment_for_connect
          @environment_report ||= Agent.config[:send_environment_info] ? Array(EnvironmentReport.new) : []
        end

        # Constructs and memoizes an event_harvest_config hash to be used in
        # the payload sent during connect (and reconnect)
        def event_harvest_config
          @event_harvest_config ||= Configuration::EventHarvestConfig.from_config(Agent.config)
        end

        # Builds the payload to send to the connect service,
        # connects, then configures the agent using the response from
        # the connect service
        def connect_to_server
          request_builder = ::NewRelic::Agent::Connect::RequestBuilder.new( \
            @service,
            Agent.config,
            event_harvest_config,
            environment_for_connect
          )
          connect_response = @service.connect(request_builder.connect_payload)

          response_handler = ::NewRelic::Agent::Connect::ResponseHandler.new(self, Agent.config)
          response_handler.configure_agent(connect_response)

          log_connection(connect_response) if connect_response
          connect_response
        end

        # Logs when we connect to the server, for debugging purposes
        # - makes sure we know if an agent has not connected
        def log_connection(config_data)
          ::NewRelic::Agent.logger.debug("Connected to NewRelic Service at #{@service.collector.name}")
          ::NewRelic::Agent.logger.debug("Agent Run       = #{@service.agent_id}.")
          ::NewRelic::Agent.logger.debug("Connection data = #{config_data.inspect}")
          if config_data['messages']&.any?
            log_collector_messages(config_data['messages'])
          end
        end

        def log_collector_messages(messages)
          messages.each do |message|
            ::NewRelic::Agent.logger.send(message['level'].downcase, message['message'])
          end
        end

        class WaitOnConnectTimeout < StandardError
        end

        # Used for testing to let us know we've actually started to wait
        def waited_on_connect?
          @waited_on_connect
        end

        def signal_connected
          @wait_on_connect_mutex.synchronize do
            @wait_on_connect_condition.signal
          end
        end

        def wait_on_connect(timeout)
          return if connected?

          @waited_on_connect = true
          NewRelic::Agent.logger.debug('Waiting on connect to complete.')

          @wait_on_connect_mutex.synchronize do
            @wait_on_connect_condition.wait(@wait_on_connect_mutex, timeout)
          end

          unless connected?
            raise WaitOnConnectTimeout, "Agent was unable to connect in #{timeout} seconds."
          end
        end

        def connect_options(options)
          {
            keep_retrying: true,
            force_reconnect: Agent.config[:force_reconnect]
          }.merge(options)
        end

        # Establish a connection to New Relic servers.
        #
        # By default, if a connection has already been established, this method
        # will be a no-op.
        #
        # @param [Hash] options
        # @option options [Boolean] :keep_retrying (true)
        #   If true, this method will block until a connection is successfully
        #   established, continuing to retry upon failure. If false, this method
        #   will return after either successfully connecting, or after failing
        #   once.
        #
        # @option options [Boolean] :force_reconnect (false)
        #   If true, this method will force establishment of a new connection
        #   with New Relic, even if there is already an existing connection.
        #   This is useful primarily when re-establishing a new connection after
        #   forking off from a parent process.
        #
        def connect(options = {})
          opts = connect_options(options)
          return unless should_connect?(opts[:force_reconnect])

          ::NewRelic::Agent.logger.debug("Connecting Process to New Relic: #$0")
          connect_to_server
          @connected_pid = $$
          @connect_state = :connected
          signal_connected
        rescue NewRelic::Agent::ForceDisconnectException => e
          handle_force_disconnect(e)
        rescue NewRelic::Agent::LicenseException => e
          handle_license_error(e)
        rescue NewRelic::Agent::UnrecoverableAgentException => e
          handle_unrecoverable_agent_error(e)
        rescue StandardError, Timeout::Error, NewRelic::Agent::ServerConnectionException => e
          retry if retry_from_error?(e, opts)
        rescue Exception => e
          ::NewRelic::Agent.logger.error('Exception of unexpected type during Agent#connect():', e)

          raise
        end

        def retry_from_error?(e, opts)
          # Allow a killed (aborting) thread to continue exiting during shutdown.
          # See: https://github.com/newrelic/newrelic-ruby-agent/issues/340
          raise if Thread.current.status == 'aborting'

          log_error(e)
          return false unless opts[:keep_retrying]

          note_connect_failure
          ::NewRelic::Agent.logger.info("Will re-attempt in #{connect_retry_period} seconds")
          sleep(connect_retry_period)
          true
        end
      end
    end
  end
end
