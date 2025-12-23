require_relative 'auth_strategy'
require_relative './../credential/auth_type'
require 'jwt'
module Twilio
  module REST
    class TokenAuthStrategy < AuthStrategy
      attr_accessor :token_manager, :token, :lock

      def initialize(token_manager)
        super(AuthType::ORGS_TOKEN)
        @token = nil
        @token_manager = token_manager
        @lock = Mutex.new
      end

      def auth_string
        token = fetch_token
        "Bearer #{token}"
      end

      def fetch_token
        @lock.synchronize do
          @token = @token_manager.fetch_access_token if @token.nil? || token_expired? || @token == ''
          return @token
        end
      end

      def token_expired?
        decoded_token = ::JWT.decode(@token, nil, false)
        exp = decoded_token[0]['exp']
        Time.at(exp) < Time.now
      end

      def requires_authentication
        true
      end
    end
  end
end
