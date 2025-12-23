# frozen_string_literal: true

require 'resolv'

module RuboCop
  module Cop
    module Style
      # Checks for hardcoded IP addresses, which can make code
      # brittle. IP addresses are likely to need to be changed when code
      # is deployed to a different server or environment, which may break
      # a deployment if forgotten. Prefer setting IP addresses in ENV or
      # other configuration.
      #
      # @example
      #
      #   # bad
      #   ip_address = '127.59.241.29'
      #
      #   # good
      #   ip_address = ENV['DEPLOYMENT_IP_ADDRESS']
      class IpAddresses < Base
        include StringHelp

        IPV6_MAX_SIZE = 45 # IPv4-mapped IPv6 is the longest
        MSG = 'Do not hardcode IP addresses.'

        def offense?(node)
          contents = node.source[1...-1]
          return false if contents.empty?

          return false if allowed_addresses.include?(contents.downcase)

          # To try to avoid doing two regex checks on every string,
          # shortcut out if the string does not look like an IP address
          return false unless potential_ip?(contents)

          ::Resolv::IPv4::Regex.match?(contents) || ::Resolv::IPv6::Regex.match?(contents)
        end

        # Dummy implementation of method in ConfigurableEnforcedStyle that is
        # called from StringHelp.
        def opposite_style_detected; end

        # Dummy implementation of method in ConfigurableEnforcedStyle that is
        # called from StringHelp.
        def correct_style_detected; end

        private

        def allowed_addresses
          allowed_addresses = cop_config['AllowedAddresses']
          Array(allowed_addresses).map(&:downcase)
        end

        def potential_ip?(str)
          # If the string is too long, it can't be an IP
          return false if too_long?(str)

          # If the string doesn't start with a colon or hexadecimal char,
          # we know it's not an IP address
          starts_with_hex_or_colon?(str)
        end

        def too_long?(str)
          str.size > IPV6_MAX_SIZE
        end

        def starts_with_hex_or_colon?(str)
          first_char = str[0].ord
          (48..58).cover?(first_char) || (65..70).cover?(first_char) || (97..102).cover?(first_char)
        end
      end
    end
  end
end
