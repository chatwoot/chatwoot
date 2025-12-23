require 'resolv'
module Geocoder
  class IpAddress < String
    PRIVATE_IPS = [
      '10.0.0.0/8',
      '172.16.0.0/12',
      '192.168.0.0/16',
    ].map { |ip| IPAddr.new(ip) }.freeze

    def initialize(ip)
      ip = ip.to_string if ip.is_a?(IPAddr)

      super(ip)
    end

    def internal?
      loopback? || private?
    end

    def loopback?
      valid? and !!(self == "0.0.0.0" or self.match(/\A127\./) or self == "::1")
    end

    def private?
      valid? && PRIVATE_IPS.any? { |ip| ip.include?(self) }
    end

    def valid?
      ip = self[/(?<=\[)(.*?)(?=\])/] || self
      !!((ip =~ Resolv::IPv4::Regex) || (ip =~ Resolv::IPv6::Regex))
    end
  end
end
