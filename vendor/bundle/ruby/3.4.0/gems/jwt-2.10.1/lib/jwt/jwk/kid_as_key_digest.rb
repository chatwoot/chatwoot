# frozen_string_literal: true

module JWT
  module JWK
    # @api private
    class KidAsKeyDigest
      def initialize(jwk)
        @jwk = jwk
      end

      def generate
        @jwk.key_digest
      end
    end
  end
end
