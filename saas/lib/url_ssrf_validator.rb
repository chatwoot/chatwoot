# frozen_string_literal: true

# Validates that a URL does not resolve to private/internal IP addresses,
# preventing Server-Side Request Forgery (SSRF) attacks.
#
# Usage:
#   UrlSsrfValidator.validate!("https://example.com/api")  # => true
#   UrlSsrfValidator.validate!("http://169.254.169.254/")   # => raises SsrfError
#   UrlSsrfValidator.safe?("http://10.0.0.1/")              # => false
module UrlSsrfValidator
  class SsrfError < StandardError; end

  # RFC 1918 / RFC 5737 / RFC 6598 private and reserved ranges
  BLOCKED_RANGES = [
    IPAddr.new('10.0.0.0/8'),
    IPAddr.new('172.16.0.0/12'),
    IPAddr.new('192.168.0.0/16'),
    IPAddr.new('127.0.0.0/8'),
    IPAddr.new('169.254.0.0/16'),   # Link-local / AWS metadata
    IPAddr.new('0.0.0.0/8'),
    IPAddr.new('100.64.0.0/10'),    # Carrier-grade NAT
    IPAddr.new('192.0.0.0/24'),
    IPAddr.new('192.0.2.0/24'),     # TEST-NET-1
    IPAddr.new('198.51.100.0/24'),  # TEST-NET-2
    IPAddr.new('203.0.113.0/24'),   # TEST-NET-3
    IPAddr.new('224.0.0.0/4'),      # Multicast
    IPAddr.new('240.0.0.0/4'),      # Reserved
    IPAddr.new('255.255.255.255/32'),
    # IPv6 private ranges
    IPAddr.new('::1/128'),          # Loopback
    IPAddr.new('fc00::/7'),         # Unique local
    IPAddr.new('fe80::/10')         # Link-local
  ].freeze

  BLOCKED_SCHEMES = %w[file ftp gopher].freeze

  class << self
    def validate!(url)
      uri = URI.parse(url.to_s.strip)
      validate_scheme!(uri)
      raise SsrfError, "Invalid URL: missing host" if uri.host.nil? || uri.host.empty?

      validate_host!(uri)
      true
    end

    def safe?(url)
      validate!(url)
    rescue SsrfError, URI::InvalidURIError, ArgumentError
      false
    end

    private

    def validate_scheme!(uri)
      scheme = uri.scheme&.downcase
      raise SsrfError, "Blocked URL scheme: #{scheme}" if BLOCKED_SCHEMES.include?(scheme)
      raise SsrfError, "Only HTTP(S) URLs are allowed" unless %w[http https].include?(scheme)
    end

    def validate_host!(uri)
      host = uri.host

      # Block raw IP addresses in private ranges
      begin
        ip = IPAddr.new(host)
        raise SsrfError, "URL resolves to blocked IP range: #{host}" if blocked_ip?(ip)

        return
      rescue IPAddr::InvalidAddressError
        # Not a raw IP, it's a hostname — resolve it
      end

      # Resolve hostname and check all resolved IPs
      resolved_ips = resolve_host(host)
      raise SsrfError, "Cannot resolve hostname: #{host}" if resolved_ips.empty?

      resolved_ips.each do |ip|
        raise SsrfError, "URL hostname #{host} resolves to blocked IP: #{ip}" if blocked_ip?(ip)
      end
    end

    def resolve_host(host)
      Resolv.getaddresses(host).map { |addr| IPAddr.new(addr) }
    rescue Resolv::ResolvError
      []
    end

    def blocked_ip?(ip)
      BLOCKED_RANGES.any? { |range| range.include?(ip) }
    end
  end
end
