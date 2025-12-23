# frozen_string_literal: true

require 'rack/protection'
require 'ipaddr'

module Rack
  module Protection
    ##
    # Prevented attack::   DNS rebinding and other Host header attacks
    # Supported browsers:: all
    # More infos::         https://en.wikipedia.org/wiki/DNS_rebinding
    #                      https://portswigger.net/web-security/host-header
    #
    # Blocks HTTP requests with an unrecognized hostname in any of the following
    # HTTP headers: Host, X-Forwarded-Host, Forwarded
    #
    # If you want to permit a specific hostname, you can pass in as the `:permitted_hosts` option:
    #
    #     use Rack::Protection::HostAuthorization, permitted_hosts: ["www.example.org", "sinatrarb.com"]
    #
    # The `:allow_if` option can also be set to a proc to use custom allow/deny logic.
    class HostAuthorization < Base
      DOT = '.'
      PORT_REGEXP = /:\d+\z/.freeze
      SUBDOMAINS = /[a-z0-9\-.]+/.freeze
      private_constant :DOT,
                       :PORT_REGEXP,
                       :SUBDOMAINS
      default_reaction :deny
      default_options allow_if: nil,
                      message: 'Host not permitted'

      def initialize(*)
        super
        @permitted_hosts = []
        @domain_hosts = []
        @ip_hosts = []
        @all_permitted_hosts = Array(options[:permitted_hosts])

        @all_permitted_hosts.each do |host|
          case host
          when String
            if host.start_with?(DOT)
              domain = host[1..-1]
              @permitted_hosts << domain.downcase
              @domain_hosts << /\A#{SUBDOMAINS}#{Regexp.escape(domain)}\z/i
            else
              @permitted_hosts << host.downcase
            end
          when IPAddr then @ip_hosts << host
          end
        end
      end

      def accepts?(env)
        return true if options[:allow_if]&.call(env)
        return true if @all_permitted_hosts.empty?

        request = Request.new(env)
        origin_host = extract_host(request.host_authority)
        forwarded_host = extract_host(request.forwarded_authority)

        debug env, "#{self.class} " \
                   "@all_permitted_hosts=#{@all_permitted_hosts.inspect} " \
                   "@permitted_hosts=#{@permitted_hosts.inspect} " \
                   "@domain_hosts=#{@domain_hosts.inspect} " \
                   "@ip_hosts=#{@ip_hosts.inspect} " \
                   "origin_host=#{origin_host.inspect} " \
                   "forwarded_host=#{forwarded_host.inspect}"

        if host_permitted?(origin_host)
          if forwarded_host.nil?
            true
          else
            host_permitted?(forwarded_host)
          end
        else
          false
        end
      end

      private

      def extract_host(authority)
        authority.to_s.split(PORT_REGEXP).first&.downcase
      end

      def host_permitted?(host)
        exact_match?(host) || domain_match?(host) || ip_match?(host)
      end

      def exact_match?(host)
        @permitted_hosts.include?(host)
      end

      def domain_match?(host)
        return false if host.nil?
        return false if host.start_with?(DOT)

        @domain_hosts.any? { |domain_host| host.match?(domain_host) }
      end

      def ip_match?(host)
        @ip_hosts.any? { |ip_host| ip_host.include?(host) }
      rescue IPAddr::InvalidAddressError
        false
      end
    end
  end
end
