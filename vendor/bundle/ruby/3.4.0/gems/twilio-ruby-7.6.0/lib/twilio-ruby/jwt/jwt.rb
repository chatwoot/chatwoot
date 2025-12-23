# frozen_string_literal: true

require 'jwt'

module Twilio
  module JWT
    autoload :AccessToken, File.join(File.dirname(__FILE__), 'access_token.rb')
    autoload :ClientCapability, File.join(File.dirname(__FILE__), 'client_capability.rb')
    autoload :TaskRouterCapability, File.join(File.dirname(__FILE__), 'task_router.rb')

    class BaseJWT
      # valid_until overrides ttl if specified
      def initialize(secret_key: nil, issuer: nil, subject: nil, nbf: nil, ttl: 3600, valid_until: nil)
        if secret_key.nil?
          raise ArgumentError, 'JWT does not have a signing key'
        end

        @secret_key = secret_key
        @issuer = issuer
        @subject = subject
        @algorithm = 'HS256'
        @nbf = nbf
        @ttl = ttl
        @valid_until = valid_until
      end

      def _generate_headers
        {}
      end

      def _generate_payload
        raise NotImplementedError
      end

      def headers
        headers = _generate_headers.clone
        headers['typ'] = 'JWT'
        headers['alg'] = @algorithm
        headers
      end

      def payload
        payload = _generate_payload.clone

        payload[:iss] = @issuer
        payload[:nbf] = @nbf || Time.now.to_i
        payload[:exp] = @valid_until.nil? ? Time.now.to_i + @ttl : @valid_until
        payload[:sub] = @subject unless @subject.nil?

        payload
      end

      def to_jwt
        ::JWT.encode payload, @secret_key, @algorithm, headers
      end
      alias to_s to_jwt
    end
  end
end
