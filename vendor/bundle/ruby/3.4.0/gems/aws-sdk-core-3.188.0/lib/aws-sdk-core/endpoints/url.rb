# frozen_string_literal: true

require 'ipaddr'

module Aws
  module Endpoints

    # @api private
    class URL
      def initialize(url)
        uri = URI(url)
        @scheme = uri.scheme
        # only support http and https schemes
        raise ArgumentError unless %w[https http].include?(@scheme)

        # do not support query
        raise ArgumentError if uri.query

        @authority = _authority(url, uri)
        @path = uri.path
        @normalized_path = uri.path + (uri.path[-1] == '/' ? '' : '/')
        @is_ip = _is_ip(uri.host)
      end

      attr_reader :scheme
      attr_reader :authority
      attr_reader :path
      attr_reader :normalized_path
      attr_reader :is_ip

      def as_json(_options = {})
        {
          'scheme' => scheme,
          'authority' => authority,
          'path' => path,
          'normalizedPath' => normalized_path,
          'isIp' => is_ip
        }
      end

      private

      def _authority(url, uri)
        # don't include port if it's default and not parsed originally
        if uri.default_port == uri.port && !url.include?(":#{uri.port}")
          uri.host
        else
          "#{uri.host}:#{uri.port}"
        end
      end

      def _is_ip(authority)
        IPAddr.new(authority)
        true
      rescue IPAddr::InvalidAddressError
        false
      end
    end
  end
end
