# frozen_string_literal: true

module JWT
  module JWA
    # Implementation of the EdDSA family of algorithms
    class Eddsa
      include JWT::JWA::SigningAlgorithm

      def initialize(alg)
        @alg = alg
      end

      def sign(data:, signing_key:)
        raise_sign_error!("Key given is a #{signing_key.class} but has to be an RbNaCl::Signatures::Ed25519::SigningKey") unless signing_key.is_a?(RbNaCl::Signatures::Ed25519::SigningKey)

        Deprecations.warning('Using Ed25519 keys is deprecated and will be removed in a future version of ruby-jwt. Please use the ruby-eddsa gem instead.')

        signing_key.sign(data)
      end

      def verify(data:, signature:, verification_key:)
        raise_verify_error!("key given is a #{verification_key.class} but has to be a RbNaCl::Signatures::Ed25519::VerifyKey") unless verification_key.is_a?(RbNaCl::Signatures::Ed25519::VerifyKey)

        Deprecations.warning('Using Ed25519 keys is deprecated and will be removed in a future version of ruby-jwt. Please use the ruby-eddsa gem instead.')

        verification_key.verify(signature, data)
      rescue RbNaCl::CryptoError
        false
      end

      register_algorithm(new('ED25519'))
      register_algorithm(new('EdDSA'))
    end
  end
end
