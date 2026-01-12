require 'resolv'
require 'ipaddr'

module UrlSafetyValidator
  # Blocked IP ranges for SSRF protection
  BLOCKED_IP_RANGES = [
    IPAddr.new('10.0.0.0/8'),       # Private Class A
    IPAddr.new('172.16.0.0/12'),    # Private Class B
    IPAddr.new('192.168.0.0/16'),   # Private Class C
    IPAddr.new('127.0.0.0/8'),      # Loopback
    IPAddr.new('169.254.0.0/16'),   # Link-local (AWS metadata service)
    IPAddr.new('0.0.0.0/8'),        # Current network
    IPAddr.new('100.64.0.0/10'),    # Carrier-grade NAT
    IPAddr.new('192.0.0.0/24'),     # IETF Protocol Assignments
    IPAddr.new('192.0.2.0/24'),     # TEST-NET-1
    IPAddr.new('198.51.100.0/24'),  # TEST-NET-2
    IPAddr.new('203.0.113.0/24'),   # TEST-NET-3
    IPAddr.new('224.0.0.0/4'),      # Multicast
    IPAddr.new('240.0.0.0/4'),      # Reserved
    IPAddr.new('255.255.255.255/32'), # Broadcast
    # IPv6 ranges
    IPAddr.new('::1/128'),          # IPv6 loopback
    IPAddr.new('fc00::/7'),         # IPv6 unique local
    IPAddr.new('fe80::/10'),        # IPv6 link-local
    IPAddr.new('ff00::/8')          # IPv6 multicast
  ].freeze

  BLOCKED_HOSTNAMES = [
    'localhost',
    'metadata.google.internal',
    '169.254.169.254',
    'metadata',
    'kubernetes.default.svc',
    'kubernetes.default'
  ].freeze

  class UnsafeUrlError < StandardError; end

  class << self
    def safe?(url)
      validate!(url)
      true
    rescue UnsafeUrlError, URI::InvalidURIError, SocketError, Resolv::ResolvError
      false
    end

    def validate!(url)
      uri = parse_and_validate_scheme(url)
      validate_host!(uri)
      resolve_and_validate_ip!(uri)
      true
    end

    private

    def parse_and_validate_scheme(url)
      uri = URI.parse(url)
      raise UnsafeUrlError, 'URL must use HTTP or HTTPS' unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)

      uri
    end

    def validate_host!(uri)
      host = uri.host&.downcase
      raise UnsafeUrlError, 'URL must have a valid host' if host.blank?
      raise UnsafeUrlError, 'Blocked hostname' if BLOCKED_HOSTNAMES.include?(host)
      raise UnsafeUrlError, 'Hostname ending with .local is not allowed' if host.end_with?('.local')
      raise UnsafeUrlError, 'Hostname ending with .internal is not allowed' if host.end_with?('.internal')

      # Check if host is an IP address directly
      validate_ip_not_blocked!(host) if ip_address?(host)
    end

    def resolve_and_validate_ip!(uri)
      host = uri.host

      # Resolve DNS to get actual IP addresses
      addresses = Resolv.getaddresses(host)
      raise UnsafeUrlError, 'Could not resolve hostname' if addresses.empty?

      # Validate all resolved IPs
      addresses.each do |addr|
        validate_ip_not_blocked!(addr)
      end
    end

    def validate_ip_not_blocked!(ip_string)
      ip = IPAddr.new(ip_string)

      BLOCKED_IP_RANGES.each do |range|
        raise UnsafeUrlError, "IP address #{ip_string} is in a blocked range" if range.include?(ip)
      end
    rescue IPAddr::InvalidAddressError
      raise UnsafeUrlError, "Invalid IP address: #{ip_string}"
    end

    def ip_address?(host)
      IPAddr.new(host)
      true
    rescue IPAddr::InvalidAddressError
      false
    end
  end
end
