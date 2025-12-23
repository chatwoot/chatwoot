# frozen_string_literal: true

module JWT
  module JWA
    # Implementation of the HMAC family of algorithms (using RbNaCl)
    class HmacRbNaCl
      include JWT::JWA::SigningAlgorithm

      def self.from_algorithm(algorithm)
        new(algorithm, ::RbNaCl::HMAC.const_get(algorithm.upcase.gsub('HS', 'SHA')))
      end

      def initialize(alg, hmac)
        @alg = alg
        @hmac = hmac
      end

      def sign(data:, signing_key:)
        Deprecations.warning("The use of the algorithm #{alg} is deprecated and will be removed in the next major version of ruby-jwt")
        hmac.auth(key_for_rbnacl(hmac, signing_key).encode('binary'), data.encode('binary'))
      end

      def verify(data:, signature:, verification_key:)
        Deprecations.warning("The use of the algorithm #{alg} is deprecated and will be removed in the next major version of ruby-jwt")
        hmac.verify(key_for_rbnacl(hmac, verification_key).encode('binary'), signature.encode('binary'), data.encode('binary'))
      rescue ::RbNaCl::BadAuthenticatorError, ::RbNaCl::LengthError
        false
      end

      register_algorithm(new('HS512256', ::RbNaCl::HMAC::SHA512256))

      private

      attr_reader :hmac

      def key_for_rbnacl(hmac, key)
        key ||= ''
        raise JWT::DecodeError, 'HMAC key expected to be a String' unless key.is_a?(String)

        return padded_empty_key(hmac.key_bytes) if key == ''

        key
      end

      def padded_empty_key(length)
        Array.new(length, 0x0).pack('C*').encode('binary')
      end
    end
  end
end
