# frozen_string_literal: true

module Twilio
  module Util
    class Configuration
      attr_accessor :account_sid, :auth_token, :http_client, :region, :edge, :logger

      def account_sid=(value)
        @account_sid = value
      end

      def auth_token=(value)
        @auth_token = value
      end

      def http_client=(value)
        @http_client = value
      end

      def region=(value)
        @region = value
      end

      def edge=(value)
        @edge = value
      end

      def logger=(value)
        @logger = value
      end
    end
  end
end
