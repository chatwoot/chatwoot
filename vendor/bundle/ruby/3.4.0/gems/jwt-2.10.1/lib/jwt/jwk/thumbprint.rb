# frozen_string_literal: true

module JWT
  module JWK
    # https://tools.ietf.org/html/rfc7638
    class Thumbprint
      attr_reader :jwk

      def initialize(jwk)
        @jwk = jwk
      end

      def generate
        ::Base64.urlsafe_encode64(
          Digest::SHA256.digest(
            JWT::JSON.generate(
              jwk.members.sort.to_h
            )
          ), padding: false
        )
      end

      alias to_s generate
    end
  end
end
