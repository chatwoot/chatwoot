# frozen_string_literal: true

require_relative 'ext'

module Datadog
  module Core
    module Configuration
      # Immutable container for the resulting settings
      class AgentSettings
        # IPv6 regular expression from
        # https://stackoverflow.com/questions/53497/regular-expression-that-matches-valid-ipv6-addresses
        # Does not match IPv4 addresses.
        IPV6_REGEXP = /\A(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\z)/.freeze # rubocop:disable Layout/LineLength

        attr_reader :adapter, :ssl, :hostname, :port, :uds_path, :timeout_seconds

        def initialize(adapter: nil, ssl: nil, hostname: nil, port: nil, uds_path: nil, timeout_seconds: nil)
          @adapter = adapter
          @ssl = ssl
          @hostname = hostname
          @port = port
          @uds_path = uds_path
          @timeout_seconds = timeout_seconds
          freeze
        end

        def url
          case adapter
          when Datadog::Core::Configuration::Ext::Agent::HTTP::ADAPTER
            hostname = self.hostname
            hostname = "[#{hostname}]" if IPV6_REGEXP.match?(hostname)
            "#{ssl ? "https" : "http"}://#{hostname}:#{port}/"
          when Datadog::Core::Configuration::Ext::Agent::UnixSocket::ADAPTER
            "unix://#{uds_path}"
          else
            raise ArgumentError, "Unexpected adapter: #{adapter}"
          end
        end

        def ==(other)
          self.class == other.class &&
            adapter == other.adapter &&
            ssl == other.ssl &&
            hostname == other.hostname &&
            port == other.port &&
            uds_path == other.uds_path &&
            timeout_seconds == other.timeout_seconds
        end
      end
    end
  end
end
