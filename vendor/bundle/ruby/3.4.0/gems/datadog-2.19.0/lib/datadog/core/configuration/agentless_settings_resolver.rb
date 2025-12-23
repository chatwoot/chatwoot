# frozen_string_literal: true

# rubocop:disable Style/*

require 'uri'

require_relative 'agent_settings_resolver'

module Datadog
  module Core
    module Configuration
      # Agent settings resolver for agentless operations (currently, telemetry
      # in agentless mode).
      #
      # The terminology gets a little confusing here, but transports communicate
      # with servers which are - for most components in the tracer - the
      # (local) agent. Hence, "agent settings" to refer to where the server
      # is located. Telemetry supports sending to the local agent but also
      # implements agentless mode where it sends directly to Datadog intake
      # endpoints. The agentless mode is configured using different settings,
      # and this class produces AgentSettings instances when in agentless mode.
      #
      # Agentless settings resolver uses the following configuration sources:
      #
      # 1. url_override constructor parameter, if provided
      # 2. Built-in default host/port/TLS settings for the backend
      #    intake endpoint
      #
      # The agentless resolver does NOT use agent settings (since it is
      # for agentless operation), specifically it ignores:
      #
      # - c.agent.host
      # - DD_AGENT_HOST
      # - c.agent.port
      # - DD_AGENT_PORT
      #
      # However, agentless resolver does respect the timeout specified via
      # c.agent.timeout_seconds or DD_TRACE_AGENT_TIMEOUT_SECONDS.
      class AgentlessSettingsResolver < AgentSettingsResolver
        # To avoid coupling this class to telemetry, the URL override is
        # taken here as a parameter instead of being read out of
        # c.telemetry.agentless_url_override. For the same reason, the
        # +url_override_source+ parameter should be set to the string
        # "c.telemetry.agentless_url_override".
        def self.call(settings, host_prefix:, url_override: nil, url_override_source: nil, logger: Datadog.logger)
          new(
            settings,
            host_prefix: host_prefix,
            url_override: url_override,
            url_override_source: url_override_source,
            logger: logger
          ).send(:call)
        end

        private

        attr_reader \
          :host_prefix,
          :url_override,
          :url_override_source

        def initialize(settings, host_prefix:, url_override: nil, url_override_source: nil, logger: Datadog.logger)
          if url_override && url_override_source.nil?
            raise ArgumentError, 'url_override_source must be provided when url_override is provided'
          end

          super(settings, logger: logger)

          @host_prefix = host_prefix
          @url_override = url_override
          @url_override_source = url_override_source
        end

        def hostname
          if should_use_uds?
            nil
          else
            configured_hostname || "#{host_prefix}.#{settings.site}"
          end
        end

        def configured_hostname
          return @configured_hostname if defined?(@configured_hostname)

          if should_use_uds?
            nil
          else
            @configured_hostname = (parsed_url.hostname if parsed_url)
          end
        end

        def configured_port
          return @configured_port if defined?(@configured_port)

          @configured_port = (parsed_url.port if parsed_url)
        end

        # Note that this method should always return true or false
        def ssl?
          if configured_hostname
            configured_ssl || false
          else
            if should_use_uds?
              false
            else
              # If no hostname is specified, we are communicating with the
              # default Datadog intake, which uses TLS.
              true
            end
          end
        end

        # Note that this method can return nil
        def configured_ssl
          return @configured_ssl if defined?(@configured_ssl)

          @configured_ssl = (parsed_url_ssl? if parsed_url)
        end

        def port
          if configured_port
            configured_port
          else
            if should_use_uds?
              nil
            else
              # If no hostname is specified, we are communicating with the
              # default Datadog intake, which exists on port 443.
              443
            end
          end
        end

        def mixed_http_and_uds
          false
        end

        def configured_uds_path
          return @configured_uds_path if defined?(@configured_uds_path)

          parsed_url_uds_path
        end

        def can_use_uds?
          # While in theory agentless transport could communicate via UDS,
          # in practice "agentless" means we are communicating with Datadog
          # infrastructure which is always remote.
          # Permit UDS for proxy usage?
          !configured_uds_path.nil?
        end

        def parsed_url
          return @parsed_url if defined?(@parsed_url)

          @parsed_url =
            if @url_override
              parsed = URI.parse(@url_override)

              # Agentless URL should never refer to a UDS?
              if http_scheme?(parsed) || unix_scheme?(parsed)
                parsed
              else
                log_warning(
                  "Invalid URI scheme '#{parsed.scheme}' for #{url_override_source}. " \
                  "Ignoring the contents of #{url_override_source}."
                )
                nil
              end
            end
        end
      end
    end
  end
end

# rubocop:enable Style/*
