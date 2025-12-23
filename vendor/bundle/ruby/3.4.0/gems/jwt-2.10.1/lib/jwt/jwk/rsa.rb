# frozen_string_literal: true

module JWT
  module JWK
    # JSON Web Key (JWK) representation of a RSA key
    class RSA < KeyBase # rubocop:disable Metrics/ClassLength
      BINARY = 2
      KTY    = 'RSA'
      KTYS   = [KTY, OpenSSL::PKey::RSA, JWT::JWK::RSA].freeze
      RSA_PUBLIC_KEY_ELEMENTS  = %i[kty n e].freeze
      RSA_PRIVATE_KEY_ELEMENTS = %i[d p q dp dq qi].freeze
      RSA_KEY_ELEMENTS = (RSA_PRIVATE_KEY_ELEMENTS + RSA_PUBLIC_KEY_ELEMENTS).freeze

      RSA_OPT_PARAMS    = %i[p q dp dq qi].freeze
      RSA_ASN1_SEQUENCE = (%i[n e d] + RSA_OPT_PARAMS).freeze # https://www.rfc-editor.org/rfc/rfc3447#appendix-A.1.2

      def initialize(key, params = nil, options = {})
        params ||= {}

        # For backwards compatibility when kid was a String
        params = { kid: params } if params.is_a?(String)

        key_params = extract_key_params(key)

        params = params.transform_keys(&:to_sym)
        check_jwk_params!(key_params, params)

        super(options, key_params.merge(params))
      end

      def keypair
        rsa_key
      end

      def private?
        rsa_key.private?
      end

      def public_key
        rsa_key.public_key
      end

      def signing_key
        rsa_key if private?
      end

      def verify_key
        rsa_key.public_key
      end

      def export(options = {})
        exported = parameters.clone
        exported.reject! { |k, _| RSA_PRIVATE_KEY_ELEMENTS.include? k } unless private? && options[:include_private] == true
        exported
      end

      def members
        RSA_PUBLIC_KEY_ELEMENTS.each_with_object({}) { |i, h| h[i] = self[i] }
      end

      def key_digest
        sequence = OpenSSL::ASN1::Sequence([OpenSSL::ASN1::Integer.new(public_key.n),
                                            OpenSSL::ASN1::Integer.new(public_key.e)])
        OpenSSL::Digest::SHA256.hexdigest(sequence.to_der)
      end

      def []=(key, value)
        raise ArgumentError, 'cannot overwrite cryptographic key attributes' if RSA_KEY_ELEMENTS.include?(key.to_sym)

        super(key, value)
      end

      private

      def rsa_key
        @rsa_key ||= self.class.create_rsa_key(jwk_attributes(*(RSA_KEY_ELEMENTS - [:kty])))
      end

      def extract_key_params(key)
        case key
        when JWT::JWK::RSA
          key.export(include_private: true)
        when OpenSSL::PKey::RSA # Accept OpenSSL key as input
          @rsa_key = key # Preserve the object to avoid recreation
          parse_rsa_key(key)
        when Hash
          key.transform_keys(&:to_sym)
        else
          raise ArgumentError, 'key must be of type OpenSSL::PKey::RSA or Hash with key parameters'
        end
      end

      def check_jwk_params!(key_params, params)
        raise ArgumentError, 'cannot overwrite cryptographic key attributes' unless (RSA_KEY_ELEMENTS & params.keys).empty?
        raise JWT::JWKError, "Incorrect 'kty' value: #{key_params[:kty]}, expected #{KTY}" unless key_params[:kty] == KTY
        raise JWT::JWKError, 'Key format is invalid for RSA' unless key_params[:n] && key_params[:e]
      end

      def parse_rsa_key(key)
        {
          kty: KTY,
          n: encode_open_ssl_bn(key.n),
          e: encode_open_ssl_bn(key.e),
          d: encode_open_ssl_bn(key.d),
          p: encode_open_ssl_bn(key.p),
          q: encode_open_ssl_bn(key.q),
          dp: encode_open_ssl_bn(key.dmp1),
          dq: encode_open_ssl_bn(key.dmq1),
          qi: encode_open_ssl_bn(key.iqmp)
        }.compact
      end

      def jwk_attributes(*attributes)
        attributes.each_with_object({}) do |attribute, hash|
          hash[attribute] = decode_open_ssl_bn(self[attribute])
        end
      end

      def encode_open_ssl_bn(key_part)
        return unless key_part

        ::JWT::Base64.url_encode(key_part.to_s(BINARY))
      end

      def decode_open_ssl_bn(jwk_data)
        self.class.decode_open_ssl_bn(jwk_data)
      end

      class << self
        def import(jwk_data)
          new(jwk_data)
        end

        def decode_open_ssl_bn(jwk_data)
          return nil unless jwk_data

          OpenSSL::BN.new(::JWT::Base64.url_decode(jwk_data), BINARY)
        end

        def create_rsa_key_using_der(rsa_parameters)
          validate_rsa_parameters!(rsa_parameters)

          sequence = RSA_ASN1_SEQUENCE.each_with_object([]) do |key, arr|
            next if rsa_parameters[key].nil?

            arr << OpenSSL::ASN1::Integer.new(rsa_parameters[key])
          end

          if sequence.size > 2 # Append "two-prime" version for private key
            sequence.unshift(OpenSSL::ASN1::Integer.new(0))

            raise JWT::JWKError, 'Creating a RSA key with a private key requires the CRT parameters to be defined' if sequence.size < RSA_ASN1_SEQUENCE.size
          end

          OpenSSL::PKey::RSA.new(OpenSSL::ASN1::Sequence(sequence).to_der)
        end

        def create_rsa_key_using_sets(rsa_parameters)
          validate_rsa_parameters!(rsa_parameters)

          OpenSSL::PKey::RSA.new.tap do |rsa_key|
            rsa_key.set_key(rsa_parameters[:n], rsa_parameters[:e], rsa_parameters[:d])
            rsa_key.set_factors(rsa_parameters[:p], rsa_parameters[:q]) if rsa_parameters[:p] && rsa_parameters[:q]
            rsa_key.set_crt_params(rsa_parameters[:dp], rsa_parameters[:dq], rsa_parameters[:qi]) if rsa_parameters[:dp] && rsa_parameters[:dq] && rsa_parameters[:qi]
          end
        end

        def create_rsa_key_using_accessors(rsa_parameters) # rubocop:disable Metrics/AbcSize
          validate_rsa_parameters!(rsa_parameters)

          OpenSSL::PKey::RSA.new.tap do |rsa_key|
            rsa_key.n = rsa_parameters[:n]
            rsa_key.e = rsa_parameters[:e]
            rsa_key.d = rsa_parameters[:d] if rsa_parameters[:d]
            rsa_key.p = rsa_parameters[:p] if rsa_parameters[:p]
            rsa_key.q = rsa_parameters[:q] if rsa_parameters[:q]
            rsa_key.dmp1 = rsa_parameters[:dp] if rsa_parameters[:dp]
            rsa_key.dmq1 = rsa_parameters[:dq] if rsa_parameters[:dq]
            rsa_key.iqmp = rsa_parameters[:qi] if rsa_parameters[:qi]
          end
        end

        def validate_rsa_parameters!(rsa_parameters)
          return unless rsa_parameters.key?(:d)

          parameters = RSA_OPT_PARAMS - rsa_parameters.keys
          return if parameters.empty? || parameters.size == RSA_OPT_PARAMS.size

          raise JWT::JWKError, 'When one of p, q, dp, dq or qi is given all the other optimization parameters also needs to be defined' # https://www.rfc-editor.org/rfc/rfc7518.html#section-6.3.2
        end

        if ::JWT.openssl_3?
          alias create_rsa_key create_rsa_key_using_der
        elsif OpenSSL::PKey::RSA.new.respond_to?(:set_key)
          alias create_rsa_key create_rsa_key_using_sets
        else
          alias create_rsa_key create_rsa_key_using_accessors
        end
      end
    end
  end
end
