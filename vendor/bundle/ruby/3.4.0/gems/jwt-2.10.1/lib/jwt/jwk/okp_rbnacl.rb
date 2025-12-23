# frozen_string_literal: true

module JWT
  module JWK
    # JSON Web Key (JWK) representation for Ed25519 keys
    class OKPRbNaCl < KeyBase
      KTY  = 'OKP'
      KTYS = [KTY, JWT::JWK::OKPRbNaCl, RbNaCl::Signatures::Ed25519::SigningKey, RbNaCl::Signatures::Ed25519::VerifyKey].freeze
      OKP_PUBLIC_KEY_ELEMENTS = %i[kty n x].freeze
      OKP_PRIVATE_KEY_ELEMENTS = %i[d].freeze

      def initialize(key, params = nil, options = {})
        params ||= {}
        Deprecations.warning('Using the OKP JWK for Ed25519 keys is deprecated and will be removed in a future version of ruby-jwt. Please use the ruby-eddsa gem instead.')
        # For backwards compatibility when kid was a String
        params = { kid: params } if params.is_a?(String)

        key_params = extract_key_params(key)

        params = params.transform_keys(&:to_sym)
        check_jwk_params!(key_params, params)
        super(options, key_params.merge(params))
      end

      def verify_key
        return @verify_key if defined?(@verify_key)

        @verify_key = verify_key_from_parameters
      end

      def signing_key
        return @signing_key if defined?(@signing_key)

        @signing_key = signing_key_from_parameters
      end

      def key_digest
        Thumbprint.new(self).to_s
      end

      def private?
        !signing_key.nil?
      end

      def members
        OKP_PUBLIC_KEY_ELEMENTS.each_with_object({}) { |i, h| h[i] = self[i] }
      end

      def export(options = {})
        exported = parameters.clone
        exported.reject! { |k, _| OKP_PRIVATE_KEY_ELEMENTS.include?(k) } unless private? && options[:include_private] == true
        exported
      end

      private

      def extract_key_params(key)
        case key
        when JWT::JWK::KeyBase
          key.export(include_private: true)
        when RbNaCl::Signatures::Ed25519::SigningKey
          @signing_key = key
          @verify_key = key.verify_key
          parse_okp_key_params(@verify_key, @signing_key)
        when RbNaCl::Signatures::Ed25519::VerifyKey
          @signing_key = nil
          @verify_key = key
          parse_okp_key_params(@verify_key)
        when Hash
          key.transform_keys(&:to_sym)
        else
          raise ArgumentError, 'key must be of type RbNaCl::Signatures::Ed25519::SigningKey, RbNaCl::Signatures::Ed25519::VerifyKey or Hash with key parameters'
        end
      end

      def check_jwk_params!(key_params, _given_params)
        raise JWT::JWKError, "Incorrect 'kty' value: #{key_params[:kty]}, expected #{KTY}" unless key_params[:kty] == KTY
      end

      def parse_okp_key_params(verify_key, signing_key = nil)
        params = {
          kty: KTY,
          crv: 'Ed25519',
          x: ::JWT::Base64.url_encode(verify_key.to_bytes)
        }

        params[:d] = ::JWT::Base64.url_encode(signing_key.to_bytes) if signing_key

        params
      end

      def verify_key_from_parameters
        RbNaCl::Signatures::Ed25519::VerifyKey.new(::JWT::Base64.url_decode(self[:x]))
      end

      def signing_key_from_parameters
        return nil unless self[:d]

        RbNaCl::Signatures::Ed25519::SigningKey.new(::JWT::Base64.url_decode(self[:d]))
      end

      class << self
        def import(jwk_data)
          new(jwk_data)
        end
      end
    end
  end
end
