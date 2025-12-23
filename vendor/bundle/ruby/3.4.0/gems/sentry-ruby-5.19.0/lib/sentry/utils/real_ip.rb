# frozen_string_literal: true

require 'ipaddr'

# Based on ActionDispatch::RemoteIp. All security-related precautions from that
# middleware have been removed, because the Event IP just needs to be accurate,
# and spoofing an IP here only makes data inaccurate, not insecure. Don't re-use
# this module if you have to *trust* the IP address.
module Sentry
  module Utils
    class RealIp
      LOCAL_ADDRESSES = [
        "127.0.0.1",      # localhost IPv4
        "::1",            # localhost IPv6
        "fc00::/7",       # private IPv6 range fc00::/7
        "10.0.0.0/8",     # private IPv4 range 10.x.x.x
        "172.16.0.0/12",  # private IPv4 range 172.16.0.0 .. 172.31.255.255
        "192.168.0.0/16" # private IPv4 range 192.168.x.x
      ]

      attr_reader :ip

      def initialize(
        remote_addr: nil,
        client_ip: nil,
        real_ip: nil,
        forwarded_for: nil,
        trusted_proxies: []
      )
        @remote_addr = remote_addr
        @client_ip = client_ip
        @real_ip = real_ip
        @forwarded_for = forwarded_for
        @trusted_proxies = (LOCAL_ADDRESSES + Array(trusted_proxies)).map do |proxy|
          if proxy.is_a?(IPAddr)
            proxy
          else
            IPAddr.new(proxy.to_s)
          end
        end.uniq
      end

      def calculate_ip
        # CGI environment variable set by Rack
        remote_addr = ips_from(@remote_addr).last

        # Could be a CSV list and/or repeated headers that were concatenated.
        client_ips    = ips_from(@client_ip)
        real_ips      = ips_from(@real_ip)

        # The first address in this list is the original client, followed by
        # the IPs of successive proxies. We want to search starting from the end
        # until we find the first proxy that we do not trust.
        forwarded_ips = ips_from(@forwarded_for).reverse

        ips = [client_ips, real_ips, forwarded_ips, remote_addr].flatten.compact

        # If every single IP option is in the trusted list, just return REMOTE_ADDR
        @ip = filter_trusted_proxy_addresses(ips).first || remote_addr
      end

      protected

      def ips_from(header)
        # Split the comma-separated list into an array of strings
        ips = header ? header.strip.split(/[,\s]+/) : []
        ips.select do |ip|
          begin
            # Only return IPs that are valid according to the IPAddr#new method
            range = IPAddr.new(ip).to_range
            # we want to make sure nobody is sneaking a netmask in
            range.begin == range.end
          rescue ArgumentError
            nil
          end
        end
      end

      def filter_trusted_proxy_addresses(ips)
        ips.reject { |ip| @trusted_proxies.any? { |proxy| proxy === ip } }
      end
    end
  end
end
