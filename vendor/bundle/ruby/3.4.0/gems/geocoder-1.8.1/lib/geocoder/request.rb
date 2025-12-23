require 'ipaddr'

module Geocoder
  module Request

    # The location() method is vulnerable to trivial IP spoofing.
    #   Don't use it in authorization/authentication code, or any
    #   other security-sensitive application.  Use safe_location
    #   instead.
    def location
      @location ||= Geocoder.search(geocoder_spoofable_ip, ip_address: true).first
    end

    # This safe_location() protects you from trivial IP spoofing.
    #   For requests that go through a proxy that you haven't
    #   whitelisted as trusted in your Rack config, you will get the
    #   location for the IP of the last untrusted proxy in the chain,
    #   not the original client IP.  You WILL NOT get the location
    #   corresponding to the original client IP for any request sent
    #   through a non-whitelisted proxy.
    def safe_location
      @safe_location ||= Geocoder.search(ip, ip_address: true).first
    end

    # There's a whole zoo of nonstandard headers added by various
    #   proxy softwares to indicate original client IP.
    # ANY of these can be trivially spoofed!
    #   (except REMOTE_ADDR, which should by set by your server,
    #    and is included at the end as a fallback.
    # Order does matter: we're following the convention established in
    #   ActionDispatch::RemoteIp::GetIp::calculate_ip()
    #   https://github.com/rails/rails/blob/master/actionpack/lib/action_dispatch/middleware/remote_ip.rb
    #   where the forwarded_for headers, possibly containing lists,
    #   are arbitrarily preferred over headers expected to contain a
    #   single address.
    GEOCODER_CANDIDATE_HEADERS = ['HTTP_X_FORWARDED_FOR',
                                  'HTTP_X_FORWARDED',
                                  'HTTP_FORWARDED_FOR',
                                  'HTTP_FORWARDED',
                                  'HTTP_X_CLIENT_IP',
                                  'HTTP_CLIENT_IP',
                                  'HTTP_X_REAL_IP',
                                  'HTTP_X_CLUSTER_CLIENT_IP',
                                  'REMOTE_ADDR']

    def geocoder_spoofable_ip

      # We could use a more sophisticated IP-guessing algorithm here,
      # in which we'd try to resolve the use of different headers by
      # different proxies.  The idea is that by comparing IPs repeated
      # in different headers, you can sometimes decide which header
      # was used by a proxy further along in the chain, and thus
      # prefer the headers used earlier.  However, the gains might not
      # be worth the performance tradeoff, since this method is likely
      # to be called on every request in a lot of applications.
      GEOCODER_CANDIDATE_HEADERS.each do |header|
        if @env.has_key? header
          addrs = geocoder_split_ip_addresses(@env[header])
          addrs = geocoder_remove_port_from_addresses(addrs)
          addrs = geocoder_reject_non_ipv4_addresses(addrs)
          addrs = geocoder_reject_trusted_ip_addresses(addrs)
          return addrs.first if addrs.any?
        end
      end

      @env['REMOTE_ADDR']
    end

    private

    def geocoder_split_ip_addresses(ip_addresses)
      ip_addresses ? ip_addresses.strip.split(/[,\s]+/) : []
    end

    # use Rack's trusted_proxy?() method to filter out IPs that have
    #   been configured as trusted; includes private ranges by
    #   default.  (we don't want every lookup to return the location
    #   of our own proxy/load balancer)
    def geocoder_reject_trusted_ip_addresses(ip_addresses)
      ip_addresses.reject { |ip| trusted_proxy?(ip) }
    end

    def geocoder_remove_port_from_addresses(ip_addresses)
      ip_addresses.map do |ip|
        # IPv4
        if ip.count('.') > 0
          ip.split(':').first
        # IPv6 bracket notation
        elsif match = ip.match(/\[(\S+)\]/)
          match.captures.first
        # IPv6 bare notation
        else
          ip
        end
      end
    end

    def geocoder_reject_non_ipv4_addresses(ip_addresses)
      ips = []
      for ip in ip_addresses
        begin
          valid_ip = IPAddr.new(ip)
        rescue
          valid_ip = false
        end
        ips << valid_ip.to_s if valid_ip
      end
      return ips.any? ? ips : ip_addresses
    end
  end
end

ActionDispatch::Request.__send__(:include, Geocoder::Request) if defined?(ActionDispatch::Request)
Rack::Request.__send__(:include, Geocoder::Request) if defined?(Rack::Request)
