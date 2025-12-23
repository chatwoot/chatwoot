# frozen_string_literal: true

module JWT
  module JWK
    # JWK for HMAC keys
    class HMAC < KeyBase
      KTY  = 'oct'
      KTYS = [KTY, String, JWT::JWK::HMAC].freeze
      HMAC_PUBLIC_KEY_ELEMENTS = %i[kty].freeze
      HMAC_PRIVATE_KEY_ELEMENTS = %i[k].freeze
      HMAC_KEY_ELEMENTS = (HMAC_PRIVATE_KEY_ELEMENTS + HMAC_PUBLIC_KEY_ELEMENTS).freeze

      def initialize(key, params = nil, options = {})
        params ||= {}

        # For backwards compatibility when kid was a String
        params = { kid: params } if params.is_a?(String)

        key_params = extract_key_params(key)

        params = params.transform_keys(&:to_sym)
        check_jwk(key_params, params)

        super(options, key_params.merge(params))
      end

      def keypair
        secret
      end

      def private?
        true
      end

      def public_key
        nil
      end

      def verify_key
        secret
      end

      def signing_key
        secret
      end

      # See https://tools.ietf.org/html/rfc7517#appendix-A.3
      def export(options = {})
        exported = parameters.clone
        exported.reject! { |k, _| HMAC_PRIVATE_KEY_ELEMENTS.include? k } unless private? && options[:include_private] == true
        exported
      end

      def members
        HMAC_KEY_ELEMENTS.each_with_object({}) { |i, h| h[i] = self[i] }
      end

      def key_digest
        sequence = OpenSSL::ASN1::Sequence([OpenSSL::ASN1::UTF8String.new(signing_key),
                                            OpenSSL::ASN1::UTF8String.new(KTY)])
        OpenSSL::Digest::SHA256.hexdigest(sequence.to_der)
      end

      def []=(key, value)
        raise ArgumentError, 'cannot overwrite cryptographic key attributes' if HMAC_KEY_ELEMENTS.include?(key.to_sym)

        super(key, value)
      end

      private

      def secret
        self[:k]
      end

      def extract_key_params(key)
        case key
        when JWT::JWK::HMAC
          key.export(include_private: true)
        when String # Accept String key as input
          { kty: KTY, k: key }
        when Hash
          key.transform_keys(&:to_sym)
        else
          raise ArgumentError, 'key must be of type String or Hash with key parameters'
        end
      end

      def check_jwk(keypair, params)
        raise ArgumentError, 'cannot overwrite cryptographic key attributes' unless (HMAC_KEY_ELEMENTS & params.keys).empty?
        raise JWT::JWKError, "Incorrect 'kty' value: #{keypair[:kty]}, expected #{KTY}" unless keypair[:kty] == KTY
        raise JWT::JWKError, 'Key format is invalid for HMAC' unless keypair[:k]
      end

      class << self
        def import(jwk_data)
          new(jwk_data)
        end
      end
    end
  end
end
