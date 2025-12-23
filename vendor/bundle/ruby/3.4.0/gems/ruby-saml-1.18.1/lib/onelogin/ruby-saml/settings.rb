require "xml_security"
require "onelogin/ruby-saml/attribute_service"
require "onelogin/ruby-saml/utils"
require "onelogin/ruby-saml/validation_error"

# Only supports SAML 2.0
module OneLogin
  module RubySaml

    # SAML2 Toolkit Settings
    #
    class Settings
      def initialize(overrides = {}, keep_security_attributes = false)
        if keep_security_attributes
          security_attributes = overrides.delete(:security) || {}
          config = DEFAULTS.merge(overrides)
          config[:security] = DEFAULTS[:security].merge(security_attributes)
        else
          config = DEFAULTS.merge(overrides)
        end

        config.each do |k,v|
          acc = "#{k}=".to_sym
          if respond_to? acc
            value = v.is_a?(Hash) ? v.dup : v
            send(acc, value)
          end
        end
        @attribute_consuming_service = AttributeService.new
      end

      # IdP Data
      attr_accessor :idp_entity_id
      attr_writer   :idp_sso_service_url
      attr_writer   :idp_slo_service_url
      attr_accessor :idp_slo_response_service_url
      attr_accessor :idp_cert
      attr_accessor :idp_cert_fingerprint
      attr_accessor :idp_cert_fingerprint_algorithm
      attr_accessor :idp_cert_multi
      attr_accessor :idp_attribute_names
      attr_accessor :idp_name_qualifier
      attr_accessor :valid_until
      # SP Data
      attr_writer   :sp_entity_id
      attr_accessor :assertion_consumer_service_url
      attr_reader   :assertion_consumer_service_binding
      attr_writer   :single_logout_service_url
      attr_accessor :sp_name_qualifier
      attr_accessor :name_identifier_format
      attr_accessor :name_identifier_value
      attr_accessor :name_identifier_value_requested
      attr_accessor :sessionindex
      attr_accessor :compress_request
      attr_accessor :compress_response
      attr_accessor :double_quote_xml_attribute_values
      attr_accessor :message_max_bytesize
      attr_accessor :check_malformed_doc
      attr_accessor :passive
      attr_reader   :protocol_binding
      attr_accessor :attributes_index
      attr_accessor :force_authn
      attr_accessor :certificate
      attr_accessor :private_key
      attr_accessor :sp_cert_multi
      attr_accessor :authn_context
      attr_accessor :authn_context_comparison
      attr_accessor :authn_context_decl_ref
      attr_reader :attribute_consuming_service
      # Work-flow
      attr_accessor :security
      attr_accessor :soft
      # Deprecated
      attr_accessor :certificate_new
      attr_accessor :assertion_consumer_logout_service_url
      attr_reader   :assertion_consumer_logout_service_binding
      attr_accessor :issuer
      attr_accessor :idp_sso_target_url
      attr_accessor :idp_slo_target_url

      # @return [String] IdP Single Sign On Service URL
      #
      def idp_sso_service_url
        @idp_sso_service_url || @idp_sso_target_url
      end

      # @return [String] IdP Single Logout Service URL
      #
      def idp_slo_service_url
        @idp_slo_service_url || @idp_slo_target_url
      end

      # @return [String] IdP Single Sign On Service Binding
      #
      def idp_sso_service_binding
        @idp_sso_service_binding || idp_binding_from_embed_sign
      end

      # Setter for IdP Single Sign On Service Binding
      # @param value [String, Symbol].
      #
      def idp_sso_service_binding=(value)
        @idp_sso_service_binding = get_binding(value)
      end

      # @return [String] IdP Single Logout Service Binding
      #
      def idp_slo_service_binding
        @idp_slo_service_binding || idp_binding_from_embed_sign
      end

      # Setter for IdP Single Logout Service Binding
      # @param value [String, Symbol].
      #
      def idp_slo_service_binding=(value)
        @idp_slo_service_binding = get_binding(value)
      end

      # @return [String] SP Entity ID
      #
      def sp_entity_id
        @sp_entity_id || @issuer
      end

      # Setter for SP Protocol Binding
      # @param value [String, Symbol].
      #
      def protocol_binding=(value)
        @protocol_binding = get_binding(value)
      end

      # Setter for SP Assertion Consumer Service Binding
      # @param value [String, Symbol].
      #
      def assertion_consumer_service_binding=(value)
        @assertion_consumer_service_binding = get_binding(value)
      end

      # @return [String] Single Logout Service URL.
      #
      def single_logout_service_url
        @single_logout_service_url || @assertion_consumer_logout_service_url
      end

      # @return [String] Single Logout Service Binding.
      #
      def single_logout_service_binding
        @single_logout_service_binding || @assertion_consumer_logout_service_binding
      end

      # Setter for Single Logout Service Binding.
      #
      # (Currently we only support "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect")
      # @param value [String, Symbol]
      #
      def single_logout_service_binding=(value)
        @single_logout_service_binding = get_binding(value)
      end

      # @deprecated Setter for legacy Single Logout Service Binding parameter.
      #
      # (Currently we only support "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect")
      # @param value [String, Symbol]
      #
      def assertion_consumer_logout_service_binding=(value)
        @assertion_consumer_logout_service_binding = get_binding(value)
      end

      # Calculates the fingerprint of the IdP x509 certificate.
      # @return [String] The fingerprint
      #
      def get_fingerprint
        idp_cert_fingerprint || begin
          idp_cert = get_idp_cert
          if idp_cert
            fingerprint_alg = XMLSecurity::BaseDocument.new.algorithm(idp_cert_fingerprint_algorithm).new
            fingerprint_alg.hexdigest(idp_cert.to_der).upcase.scan(/../).join(":")
          end
        end
      end

      # @return [OpenSSL::X509::Certificate|nil] Build the IdP certificate from the settings (previously format it)
      #
      def get_idp_cert
        OneLogin::RubySaml::Utils.build_cert_object(idp_cert)
      end

      # @return [Hash with 2 arrays of OpenSSL::X509::Certificate] Build multiple IdP certificates from the settings.
      #
      def get_idp_cert_multi
        return nil if idp_cert_multi.nil? || idp_cert_multi.empty?

        raise ArgumentError.new("Invalid value for idp_cert_multi") unless idp_cert_multi.is_a?(Hash)

        certs = {:signing => [], :encryption => [] }

        [:signing, :encryption].each do |type|
          certs_for_type = idp_cert_multi[type] || idp_cert_multi[type.to_s]
          next if !certs_for_type || certs_for_type.empty?

          certs_for_type.each do |idp_cert|
            certs[type].push(OneLogin::RubySaml::Utils.build_cert_object(idp_cert))
          end
        end

        certs
      end

      # @return [Hash<Symbol, Array<Array<OpenSSL::X509::Certificate, OpenSSL::PKey::RSA>>>]
      #   Build the SP certificates and private keys from the settings. If
      #   check_sp_cert_expiration is true, only returns certificates and private keys
      #   that are not expired.
      def get_sp_certs
        certs = get_all_sp_certs
        return certs unless security[:check_sp_cert_expiration]

        active_certs = { signing: [], encryption: [] }
        certs.each do |use, pairs|
          next if pairs.empty?

          pairs = pairs.select { |cert, _| !cert || OneLogin::RubySaml::Utils.is_cert_active(cert) }
          raise OneLogin::RubySaml::ValidationError.new("The SP certificate expired.") if pairs.empty?

          active_certs[use] = pairs.freeze
        end
        active_certs.freeze
      end

      # @return [Array<OpenSSL::X509::Certificate, OpenSSL::PKey::RSA>]
      #   The SP signing certificate and private key.
      def get_sp_signing_pair
        get_sp_certs[:signing].first
      end

      # @return [OpenSSL::X509::Certificate] The SP signing certificate.
      # @deprecated Use get_sp_signing_pair or get_sp_certs instead.
      def get_sp_cert
        node = get_sp_signing_pair
        node[0] if node
      end

      # @return [OpenSSL::PKey::RSA] The SP signing key.
      def get_sp_signing_key
        node = get_sp_signing_pair
        node[1] if node
      end

      # @deprecated Use get_sp_signing_key or get_sp_certs instead.
      alias_method :get_sp_key, :get_sp_signing_key

      # @return [Array<OpenSSL::PKey::RSA>] The SP decryption keys.
      def get_sp_decryption_keys
        ary = get_sp_certs[:encryption].map { |pair| pair[1] }
        ary.compact!
        ary.uniq!(&:to_pem)
        ary.freeze
      end

      # @return [OpenSSL::X509::Certificate|nil] Build the New SP certificate from the settings.
      #
      # @deprecated Use get_sp_certs instead
      def get_sp_cert_new
        node = get_sp_certs[:signing].last
        node[0] if node
      end

      def idp_binding_from_embed_sign
        security[:embed_sign] ? Utils::BINDINGS[:post] : Utils::BINDINGS[:redirect]
      end

      def get_binding(value)
        return unless value

        Utils::BINDINGS[value.to_sym] || value
      end

      DEFAULTS = {
        :assertion_consumer_service_binding        => Utils::BINDINGS[:post],
        :single_logout_service_binding             => Utils::BINDINGS[:redirect],
        :idp_cert_fingerprint_algorithm            => XMLSecurity::Document::SHA1,
        :compress_request                          => true,
        :compress_response                         => true,
        :message_max_bytesize                      => 250000,
        :soft                                      => true,
        :check_malformed_doc                       => true,
        :double_quote_xml_attribute_values         => false,
        
        :security                                  => {
          :authn_requests_signed      => false,
          :logout_requests_signed     => false,
          :logout_responses_signed    => false,
          :want_assertions_signed     => false,
          :want_assertions_encrypted  => false,
          :want_name_id               => false,
          :metadata_signed            => false,
          :embed_sign                 => false, # Deprecated
          :digest_method              => XMLSecurity::Document::SHA1,
          :signature_method           => XMLSecurity::Document::RSA_SHA1,
          :check_idp_cert_expiration  => false,
          :check_sp_cert_expiration   => false,
          :strict_audience_validation => false,
          :lowercase_url_encoding     => false
        }.freeze
      }.freeze

      private

      # @return [Hash<Symbol, Array<Array<OpenSSL::X509::Certificate, OpenSSL::PKey::RSA>>>]
      #   Build the SP certificates and private keys from the settings. Returns all
      #   certificates and private keys, even if they are expired.
      def get_all_sp_certs
        validate_sp_certs_params!
        get_sp_certs_multi || get_sp_certs_single
      end

      # Validate certificate, certificate_new, private_key, and sp_cert_multi params.
      def validate_sp_certs_params!
        multi    = sp_cert_multi   && !sp_cert_multi.empty?
        cert     = certificate     && !certificate.empty?
        cert_new = certificate_new && !certificate_new.empty?
        pk       = private_key     && !private_key.empty?
        if multi && (cert || cert_new || pk)
          raise ArgumentError.new("Cannot specify both sp_cert_multi and certificate, certificate_new, private_key parameters")
        end
      end

      # Get certs from certificate, certificate_new, and private_key parameters.
      def get_sp_certs_single
        certs = { :signing => [], :encryption => [] }

        sp_key = OneLogin::RubySaml::Utils.build_private_key_object(private_key)
        cert = OneLogin::RubySaml::Utils.build_cert_object(certificate)
        if cert || sp_key
          ary = [cert, sp_key].freeze
          certs[:signing] << ary
          certs[:encryption] << ary
        end

        cert_new = OneLogin::RubySaml::Utils.build_cert_object(certificate_new)
        if cert_new
          ary = [cert_new, sp_key].freeze
          certs[:signing] << ary
          certs[:encryption] << ary
        end

        certs
      end

      # Get certs from get_sp_cert_multi parameter.
      def get_sp_certs_multi
        return if sp_cert_multi.nil? || sp_cert_multi.empty?

        raise ArgumentError.new("sp_cert_multi must be a Hash") unless sp_cert_multi.is_a?(Hash)

        certs = { :signing => [], :encryption => [] }.freeze

        [:signing, :encryption].each do |type|
          certs_for_type = sp_cert_multi[type] || sp_cert_multi[type.to_s]
          next if !certs_for_type || certs_for_type.empty?

          unless certs_for_type.is_a?(Array) && certs_for_type.all? { |cert| cert.is_a?(Hash) }
            raise ArgumentError.new("sp_cert_multi :#{type} node must be an Array of Hashes")
          end

          certs_for_type.each do |pair|
            cert = pair[:certificate] || pair['certificate'] || pair[:cert] || pair['cert']
            key  = pair[:private_key] || pair['private_key'] || pair[:key] || pair['key']

            unless cert && key
              raise ArgumentError.new("sp_cert_multi :#{type} node Hashes must specify keys :certificate and :private_key")
            end

            certs[type] << [
              OneLogin::RubySaml::Utils.build_cert_object(cert),
              OneLogin::RubySaml::Utils.build_private_key_object(key)
            ].freeze
          end
        end

        certs.each { |_, ary| ary.freeze }
        certs
      end
    end
  end
end

