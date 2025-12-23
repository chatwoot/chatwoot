# frozen_string_literal: true

module JWT
  module JWA
    # Implementation of the HMAC family of algorithms (using RbNaCl prior to a certain version)
    class HmacRbNaClFixed
      include JWT::JWA::SigningAlgorithm

      def self.from_algorithm(algorithm)
        new(algorithm, ::RbNaCl::HMAC.const_get(algorithm.upcase.gsub('HS', 'SHA')))
      end

      def initialize(alg, hmac)
        @alg = alg
        @hmac = hmac
      end

      def sign(data:, signing_key:)
        signing_key ||= ''
        Deprecations.warning("The use of the algorithm #{alg} is deprecated and will be removed in the next major version of ruby-jwt")
        raise JWT::DecodeError, 'HMAC key expected to be a String' unless signing_key.is_a?(String)

        hmac.auth(padded_key_bytes(signing_key, hmac.key_bytes), data.encode('binary'))
      end

      def verify(data:, signature:, verification_key:)
        verification_key ||= ''
        Deprecations.warning("The use of the algorithm #{alg} is deprecated and will be removed in the next major version of ruby-jwt")
        raise JWT::DecodeError, 'HMAC key expected to be a String' unless verification_key.is_a?(String)

        hmac.verify(padded_key_bytes(verification_key, hmac.key_bytes), signature.encode('binary'), data.encode('binary'))
      rescue ::RbNaCl::BadAuthenticatorError, ::RbNaCl::LengthError
        false
      end

      register_algorithm(new('HS512256', ::RbNaCl::HMAC::SHA512256))

      private

      attr_reader :hmac

      def padded_key_bytes(key, bytesize)
        key.bytes.fill(0, key.bytesize...bytesize).pack('C*')
      end
    end
  end
end
