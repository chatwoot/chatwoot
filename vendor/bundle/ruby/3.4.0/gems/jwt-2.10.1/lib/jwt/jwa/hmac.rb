# frozen_string_literal: true

module JWT
  module JWA
    # Implementation of the HMAC family of algorithms
    class Hmac
      include JWT::JWA::SigningAlgorithm

      def self.from_algorithm(algorithm)
        new(algorithm, OpenSSL::Digest.new(algorithm.downcase.gsub('hs', 'sha')))
      end

      def initialize(alg, digest)
        @alg = alg
        @digest = digest
      end

      def sign(data:, signing_key:)
        signing_key ||= ''
        raise_verify_error!('HMAC key expected to be a String') unless signing_key.is_a?(String)

        OpenSSL::HMAC.digest(digest.new, signing_key, data)
      rescue OpenSSL::HMACError => e
        raise_verify_error!('OpenSSL 3.0 does not support nil or empty hmac_secret') if signing_key == '' && e.message == 'EVP_PKEY_new_mac_key: malloc failure'

        raise e
      end

      def verify(data:, signature:, verification_key:)
        SecurityUtils.secure_compare(signature, sign(data: data, signing_key: verification_key))
      end

      register_algorithm(new('HS256', OpenSSL::Digest::SHA256))
      register_algorithm(new('HS384', OpenSSL::Digest::SHA384))
      register_algorithm(new('HS512', OpenSSL::Digest::SHA512))

      private

      attr_reader :digest

      # Copy of https://github.com/rails/rails/blob/v7.0.3.1/activesupport/lib/active_support/security_utils.rb
      # rubocop:disable Naming/MethodParameterName, Style/StringLiterals, Style/NumericPredicate
      module SecurityUtils
        # Constant time string comparison, for fixed length strings.
        #
        # The values compared should be of fixed length, such as strings
        # that have already been processed by HMAC. Raises in case of length mismatch.

        if defined?(OpenSSL.fixed_length_secure_compare)
          def fixed_length_secure_compare(a, b)
            OpenSSL.fixed_length_secure_compare(a, b)
          end
        else
          # :nocov:
          def fixed_length_secure_compare(a, b)
            raise ArgumentError, "string length mismatch." unless a.bytesize == b.bytesize

            l = a.unpack "C#{a.bytesize}"

            res = 0
            b.each_byte { |byte| res |= byte ^ l.shift }
            res == 0
          end
          # :nocov:
        end
        module_function :fixed_length_secure_compare

        # Secure string comparison for strings of variable length.
        #
        # While a timing attack would not be able to discern the content of
        # a secret compared via secure_compare, it is possible to determine
        # the secret length. This should be considered when using secure_compare
        # to compare weak, short secrets to user input.
        def secure_compare(a, b)
          a.bytesize == b.bytesize && fixed_length_secure_compare(a, b)
        end
        module_function :secure_compare
      end
      # rubocop:enable Naming/MethodParameterName, Style/StringLiterals, Style/NumericPredicate
    end
  end
end
