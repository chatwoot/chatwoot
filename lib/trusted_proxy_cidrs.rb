# frozen_string_literal: true

require 'ipaddr'

# Parses TRUSTED_PROXY_CIDRS-style CSV into IPAddr instances for ActionDispatch::RemoteIp.
module TrustedProxyCidrs
  module_function

  def build_from_env(value)
    cidr_strings = value.to_s.split(',').map(&:strip).reject(&:empty?)
    return [] if cidr_strings.empty?

    cidr_strings.map do |cidr|
      IPAddr.new(cidr)
    rescue IPAddr::InvalidAddressError => e
      raise ArgumentError,
            "TRUSTED_PROXY_CIDRS contains invalid CIDR #{cidr.inspect}: #{e.message}"
    end
  end
end
