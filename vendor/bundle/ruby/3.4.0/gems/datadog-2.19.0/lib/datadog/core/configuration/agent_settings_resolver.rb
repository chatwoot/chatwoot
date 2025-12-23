# frozen_string_literal: true

require 'uri'

require_relative 'settings'
require_relative 'ext'
require_relative 'agent_settings'
require_relative '../transport/ext'

module Datadog
  module Core
    module Configuration
      # This class unifies all the different ways that users can configure how we talk to the agent.
      #
      # It has quite a lot of complexity, but this complexity just reflects the actual complexity we have around our
      # configuration today. E.g., this is just all of the complexity regarding agent settings gathered together in a
      # single place. As we deprecate more and more of the different ways that these things can be configured,
      # this class will reflect that simplification as well.
      #
      # Whenever there is a conflict (different configurations are provided in different orders), it MUST warn the users
      # about it and pick a value based on the following priority: code > environment variable > defaults.
      class AgentSettingsResolver
        def self.call(settings, logger: Datadog.logger)
          new(settings, logger: logger).send(:call)
        end

        private

        attr_reader \
          :logger,
          :settings

        def initialize(settings, logger: Datadog.logger)
          @settings = settings
          @logger = logger
        end

        def call
          AgentSettings.new(
            adapter: adapter,
            ssl: ssl?,
            hostname: hostname,
            port: port,
            uds_path: uds_path,
            timeout_seconds: timeout_seconds,
          )
        end

        def adapter
          if should_use_uds?
            Datadog::Core::Configuration::Ext::Agent::UnixSocket::ADAPTER
          else
            Datadog::Core::Configuration::Ext::Agent::HTTP::ADAPTER
          end
        end

        def configured_hostname
          return @configured_hostname if defined?(@configured_hostname)

          @configured_hostname = pick_from(
            DetectedConfiguration.new(
              friendly_name: "'c.agent.host'",
              value: settings.agent.host
            ),
            DetectedConfiguration.new(
              friendly_name: "#{Datadog::Core::Configuration::Ext::Agent::ENV_DEFAULT_URL} environment variable",
              value: parsed_http_url&.hostname
            ),
            DetectedConfiguration.new(
              friendly_name: "#{Datadog::Core::Configuration::Ext::Agent::ENV_DEFAULT_HOST} environment variable",
              value: ENV[Datadog::Core::Configuration::Ext::Agent::ENV_DEFAULT_HOST]
            )
          )
        end

        def configured_port
          return @configured_port if defined?(@configured_port)

          @configured_port = pick_from(
            try_parsing_as_integer(
              friendly_name: '"c.agent.port"',
              value: settings.agent.port,
            ),
            DetectedConfiguration.new(
              friendly_name: "#{Datadog::Core::Configuration::Ext::Agent::ENV_DEFAULT_URL} environment variable",
              value: parsed_http_url&.port,
            ),
            try_parsing_as_integer(
              friendly_name: "#{Datadog::Core::Configuration::Ext::Agent::ENV_DEFAULT_PORT} environment variable",
              value: ENV[Datadog::Core::Configuration::Ext::Agent::ENV_DEFAULT_PORT],
            )
          )
        end

        def configured_ssl
          return @configured_ssl if defined?(@configured_ssl)

          @configured_ssl = pick_from(
            DetectedConfiguration.new(
              friendly_name: '"c.agent.use_ssl"',
              value: settings.agent.use_ssl,
            ),
            DetectedConfiguration.new(
              friendly_name: "#{Datadog::Core::Configuration::Ext::Agent::ENV_DEFAULT_URL} environment variable",
              value: parsed_url_ssl?,
            )
          )
        end

        def configured_timeout_seconds
          return @configured_timeout_seconds if defined?(@configured_timeout_seconds)

          @configured_timeout_seconds = pick_from(
            try_parsing_as_integer(
              friendly_name: '"c.agent.timeout_seconds"',
              value: settings.agent.timeout_seconds,
            ),
            try_parsing_as_integer(
              friendly_name: "#{Datadog::Core::Configuration::Ext::Agent::ENV_DEFAULT_TIMEOUT_SECONDS} " \
                'environment variable',
              value: ENV[Datadog::Core::Configuration::Ext::Agent::ENV_DEFAULT_TIMEOUT_SECONDS],
            )
          )
        end

        def configured_uds_path
          return @configured_uds_path if defined?(@configured_uds_path)

          @configured_uds_path = pick_from(
            DetectedConfiguration.new(
              friendly_name: "'c.agent.uds_path'",
              value: settings.agent.uds_path
            ),
            DetectedConfiguration.new(
              friendly_name: "#{Datadog::Core::Configuration::Ext::Agent::ENV_DEFAULT_URL} environment variable",
              value: parsed_url_uds_path
            )
          )
        end

        def parsed_url_ssl?
          return nil if parsed_url.nil?

          parsed_url.scheme == 'https'
        end

        def try_parsing_as_integer(value:, friendly_name:)
          value =
            begin
              Integer(value) if value
            rescue ArgumentError, TypeError
              log_warning("Invalid value for #{friendly_name} (#{value.inspect}). Ignoring this configuration.")

              nil
            end

          DetectedConfiguration.new(friendly_name: friendly_name, value: value)
        end

        def ssl?
          if should_use_uds?
            false
          else
            configured_ssl || Datadog::Core::Configuration::Ext::Agent::HTTP::DEFAULT_USE_SSL
          end
        end

        def hostname
          configured_hostname || (should_use_uds? ? nil : Datadog::Core::Configuration::Ext::Agent::HTTP::DEFAULT_HOST)
        end

        def port
          configured_port || (should_use_uds? ? nil : Datadog::Core::Configuration::Ext::Agent::HTTP::DEFAULT_PORT)
        end

        def timeout_seconds
          return configured_timeout_seconds unless configured_timeout_seconds.nil?

          if should_use_uds?
            Datadog::Core::Configuration::Ext::Agent::UnixSocket::DEFAULT_TIMEOUT_SECONDS
          else
            Datadog::Core::Configuration::Ext::Agent::HTTP::DEFAULT_TIMEOUT_SECONDS
          end
        end

        def parsed_url_uds_path
          return nil unless parsed_url && unix_scheme?(parsed_url)

          path = parsed_url.to_s
          # Some versions of the built-in uri gem leave the original url untouched, and others remove the //, so this
          # supports both
          if path.start_with?('unix://')
            path.sub('unix://', '')
          else
            path.sub('unix:', '')
          end
        end

        # Unix socket path in the file system
        def uds_path
          return nil unless should_use_uds?

          configured_uds_path || uds_fallback
        end

        # We only use the default unix socket if it is already present.
        # This is by design, as we still want to use the default host:port if no unix socket is present.
        def uds_fallback
          return @uds_fallback if defined?(@uds_fallback)

          @uds_fallback =
            if configured_hostname.nil? &&
                configured_port.nil? &&
                File.exist?(Datadog::Core::Configuration::Ext::Agent::UnixSocket::DEFAULT_PATH)

              Datadog::Core::Configuration::Ext::Agent::UnixSocket::DEFAULT_PATH
            end
        end

        def should_use_uds?
          # When we have mixed settings for http/https and uds, we print a warning
          # and use the uds settings.
          mixed_http_and_uds
          can_use_uds?
        end

        def mixed_http_and_uds
          return @mixed_http_and_uds if defined?(@mixed_http_and_uds)

          @mixed_http_and_uds = (configured_hostname || configured_port) && can_use_uds?
          if @mixed_http_and_uds
            warn_if_configuration_mismatch(
              [
                DetectedConfiguration.new(
                  friendly_name: 'configuration for unix domain socket',
                  value: parsed_url.to_s,
                ),
                DetectedConfiguration.new(
                  friendly_name: 'configuration of hostname/port for http/https use',
                  value: "hostname: '#{hostname}', port: '#{port}'",
                ),
              ]
            )
          end

          @mixed_http_and_uds
        end

        def can_use_uds?
          !configured_uds_path.nil? ||
            # If no agent settings have been provided, we try to connect using a local unix socket.
            # We only do so if the socket is present when `datadog` runs.
            !uds_fallback.nil?
        end

        def parsed_url
          return @parsed_url if defined?(@parsed_url)

          unparsed_url_from_env = ENV[Datadog::Core::Configuration::Ext::Agent::ENV_DEFAULT_URL]

          @parsed_url =
            if unparsed_url_from_env
              parsed = URI.parse(unparsed_url_from_env)

              if http_scheme?(parsed) || unix_scheme?(parsed)
                parsed
              else
                # rubocop:disable Layout/LineLength
                log_warning(
                  "Invalid URI scheme '#{parsed.scheme}' for #{Datadog::Core::Configuration::Ext::Agent::ENV_DEFAULT_URL} " \
                  "environment variable ('#{unparsed_url_from_env}'). " \
                  "Ignoring the contents of #{Datadog::Core::Configuration::Ext::Agent::ENV_DEFAULT_URL}."
                )
                # rubocop:enable Layout/LineLength

                nil
              end
            end
        end

        def pick_from(*configurations_in_priority_order)
          detected_configurations_in_priority_order = configurations_in_priority_order.select(&:value?)

          if detected_configurations_in_priority_order.any?
            warn_if_configuration_mismatch(detected_configurations_in_priority_order)

            # The configurations are listed in priority, so we only need to look at the first; if there's more than
            # one, we emit a warning above
            detected_configurations_in_priority_order.first.value
          end
        end

        def warn_if_configuration_mismatch(detected_configurations_in_priority_order)
          return unless detected_configurations_in_priority_order.map(&:value).uniq.size > 1

          log_warning(
            'Configuration mismatch: values differ between ' \
            "#{detected_configurations_in_priority_order
              .map { |config| "#{config.friendly_name} (#{config.value.inspect})" }.join(" and ")}" \
            ". Using #{detected_configurations_in_priority_order.first.value.inspect} and ignoring other configuration."
          )
        end

        def log_warning(message)
          logger&.warn(message)
        end

        def http_scheme?(uri)
          ['http', 'https'].include?(uri.scheme)
        end

        # Expected to return nil (not false!) when it's not http
        def parsed_http_url
          parsed_url if parsed_url && http_scheme?(parsed_url)
        end

        def unix_scheme?(uri)
          uri.scheme == 'unix'
        end

        # Represents a given configuration value and where we got it from
        class DetectedConfiguration
          attr_reader :friendly_name, :value

          def initialize(friendly_name:, value:)
            @friendly_name = friendly_name
            @value = value
            freeze
          end

          def value?
            !value.nil?
          end
        end
        private_constant :DetectedConfiguration
      end
    end
  end
end
