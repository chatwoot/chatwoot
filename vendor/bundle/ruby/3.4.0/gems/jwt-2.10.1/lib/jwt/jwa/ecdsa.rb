# frozen_string_literal: true

module JWT
  module JWA
    # ECDSA signing algorithm
    class Ecdsa
      include JWT::JWA::SigningAlgorithm

      def initialize(alg, digest)
        @alg = alg
        @digest = OpenSSL::Digest.new(digest)
      end

      def sign(data:, signing_key:)
        curve_definition = curve_by_name(signing_key.group.curve_name)
        key_algorithm = curve_definition[:algorithm]
        raise IncorrectAlgorithm, "payload algorithm is #{alg} but #{key_algorithm} signing key was provided" if alg != key_algorithm

        asn1_to_raw(signing_key.dsa_sign_asn1(digest.digest(data)), signing_key)
      end

      def verify(data:, signature:, verification_key:)
        curve_definition = curve_by_name(verification_key.group.curve_name)
        key_algorithm = curve_definition[:algorithm]
        raise IncorrectAlgorithm, "payload algorithm is #{alg} but #{key_algorithm} verification key was provided" if alg != key_algorithm

        verification_key.dsa_verify_asn1(digest.digest(data), raw_to_asn1(signature, verification_key))
      rescue OpenSSL::PKey::PKeyError
        raise JWT::VerificationError, 'Signature verification raised'
      end

      NAMED_CURVES = {
        'prime256v1' => {
          algorithm: 'ES256',
          digest: 'sha256'
        },
        'secp256r1' => { # alias for prime256v1
          algorithm: 'ES256',
          digest: 'sha256'
        },
        'secp384r1' => {
          algorithm: 'ES384',
          digest: 'sha384'
        },
        'secp521r1' => {
          algorithm: 'ES512',
          digest: 'sha512'
        },
        'secp256k1' => {
          algorithm: 'ES256K',
          digest: 'sha256'
        }
      }.freeze

      NAMED_CURVES.each_value do |v|
        register_algorithm(new(v[:algorithm], v[:digest]))
      end

      def self.from_algorithm(algorithm)
        new(algorithm, algorithm.downcase.gsub('es', 'sha'))
      end

      def self.curve_by_name(name)
        NAMED_CURVES.fetch(name) do
          raise UnsupportedEcdsaCurve, "The ECDSA curve '#{name}' is not supported"
        end
      end

      private

      attr_reader :digest

      def curve_by_name(name)
        self.class.curve_by_name(name)
      end

      def raw_to_asn1(signature, private_key)
        byte_size = (private_key.group.degree + 7) / 8
        sig_bytes = signature[0..(byte_size - 1)]
        sig_char = signature[byte_size..-1] || ''
        OpenSSL::ASN1::Sequence.new([sig_bytes, sig_char].map { |int| OpenSSL::ASN1::Integer.new(OpenSSL::BN.new(int, 2)) }).to_der
      end

      def asn1_to_raw(signature, public_key)
        byte_size = (public_key.group.degree + 7) / 8
        OpenSSL::ASN1.decode(signature).value.map { |value| value.value.to_s(2).rjust(byte_size, "\x00") }.join
      end
    end
  end
end
