# frozen_string_literal: true

require "ipaddr"

module WebConsole
  class Permissions
    # IPv4 and IPv6 localhost should be always allowed.
    ALWAYS_PERMITTED_NETWORKS = %w( 127.0.0.0/8 ::1 )

    def initialize(networks = nil)
      @networks = normalize_networks(networks).map(&method(:coerce_network_to_ipaddr)).uniq
    end

    def include?(network)
      @networks.any? { |permission| permission.include?(network.to_s) }
    rescue IPAddr::InvalidAddressError
      false
    end

    def to_s
      @networks.map(&method(:human_readable_ipaddr)).join(", ")
    end

    private

      def normalize_networks(networks)
        Array(networks).concat(ALWAYS_PERMITTED_NETWORKS)
      end

      def coerce_network_to_ipaddr(network)
        if network.is_a?(IPAddr)
          network
        else
          IPAddr.new(network)
        end
      end

      def human_readable_ipaddr(ipaddr)
        ipaddr.to_range.to_s.split("..").uniq.join("/")
      end
  end
end
