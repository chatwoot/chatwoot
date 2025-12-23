# frozen_string_literal: true

# XXX: Remove when removing AbstractRequest#request
require_relative '../../request'

module Rack
  module Auth
    class AbstractRequest

      def initialize(env)
        @env = env
      end

      def request
        warn "Rack::Auth::AbstractRequest#request is deprecated and will be removed in a future version of rack.", uplevel: 1
        @request ||= Request.new(@env)
      end

      def provided?
        !authorization_key.nil? && valid?
      end

      def valid?
        !@env[authorization_key].nil?
      end

      def parts
        @parts ||= @env[authorization_key].split(' ', 2)
      end

      def scheme
        @scheme ||= parts.first&.downcase
      end

      def params
        @params ||= parts.last
      end


      private

      AUTHORIZATION_KEYS = ['HTTP_AUTHORIZATION', 'X-HTTP_AUTHORIZATION', 'X_HTTP_AUTHORIZATION']

      def authorization_key
        @authorization_key ||= AUTHORIZATION_KEYS.detect { |key| @env.has_key?(key) }
      end

    end

  end
end
