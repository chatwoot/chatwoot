# frozen_string_literal: true

require 'ipaddr'

module Datadog
  module Core
    module Utils
      # Common Network utility functions.
      module Network
        DEFAULT_IP_HEADERS_NAMES = %w[
          x-forwarded-for
          x-real-ip
          true-client-ip
          x-client-ip
          x-forwarded
          forwarded-for
          x-cluster-client-ip
          fastly-client-ip
          cf-connecting-ip
          cf-connecting-ipv6
        ].freeze

        class << self
          # Returns a client IP associated with the request if it was
          #   retrieved successfully.
          #
          #
          # @param [Datadog::Core::HeaderCollection, #get, nil] headers The request headers
          # @param [Array<String>] list of headers to check.
          # @return [String] IP value without the port and the zone indentifier.
          # @return [nil] when no valid IP value found.
          def stripped_ip_from_request_headers(headers, ip_headers_to_check: DEFAULT_IP_HEADERS_NAMES)
            ip = ip_header(headers, ip_headers_to_check)

            ip&.to_s
          end

          # @param [String] IP value.
          # @return [String] IP value without the port and the zone indentifier.
          # @return [nil] when no valid IP value found.
          def stripped_ip(ip)
            ip = ip_to_ipaddr(ip)
            ip&.to_s
          end

          private

          # @param [String] IP value.
          # @return [IPaddr]
          # @return [nil] when no valid IP value found.
          def ip_to_ipaddr(ip)
            return unless ip

            clean_ip = if likely_ipv4?(ip)
              strip_ipv4_port(ip)
            else
              strip_zone_specifier(strip_ipv6_port(ip))
            end

            begin
              IPAddr.new(clean_ip)
            rescue IPAddr::Error
              nil
            end
          end

          def ip_header(headers, ip_headers_to_check)
            return unless headers

            ip_headers_to_check.each do |name|
              value = headers.get(name)

              next unless value

              ips = value.split(',')
              ips.each do |ip|
                parsed_ip = ip_to_ipaddr(ip.strip)

                return parsed_ip if global_ip?(parsed_ip)
              end
            end

            nil
          end

          # Returns whether the given value is more likely to be an IPv4 than an IPv6 address.
          #
          # This is done by checking if a dot (`'.'`) character appears before a colon (`':'`) in the value.
          # The rationale is that in valid IPv6 addresses, colons will always preced dots,
          #   and in valid IPv4 addresses dots will always preced colons.
          def likely_ipv4?(value)
            dot_index = value.index('.') || value.size
            colon_index = value.index(':') || value.size

            dot_index < colon_index
          end

          def strip_zone_specifier(ipv6)
            ipv6.gsub(/%.*/, '')
          end

          def strip_ipv6_port(ip)
            if /\[([^\]]*+)\](?::\d+)?/ =~ ip
              Regexp.last_match(1)
            else
              ip
            end
          end

          def strip_ipv4_port(ip)
            ip.gsub(/:\d+\z/, '')
          end

          def global_ip?(parsed_ip)
            parsed_ip && !parsed_ip.private? && !parsed_ip.loopback? && !parsed_ip.link_local?
          end
        end
      end
    end
  end
end
