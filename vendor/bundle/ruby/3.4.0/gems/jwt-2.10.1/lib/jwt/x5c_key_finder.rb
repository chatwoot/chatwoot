# frozen_string_literal: true

module JWT
  # If the x5c header certificate chain can be validated by trusted root
  # certificates, and none of the certificates are revoked, returns the public
  # key from the first certificate.
  # See https://tools.ietf.org/html/rfc7515#section-4.1.6
  class X5cKeyFinder
    def initialize(root_certificates, crls = nil)
      raise ArgumentError, 'Root certificates must be specified' unless root_certificates

      @store = build_store(root_certificates, crls)
    end

    def from(x5c_header_or_certificates)
      signing_certificate, *certificate_chain = parse_certificates(x5c_header_or_certificates)
      store_context = OpenSSL::X509::StoreContext.new(@store, signing_certificate, certificate_chain)

      if store_context.verify
        signing_certificate.public_key
      else
        error = "Certificate verification failed: #{store_context.error_string}."
        if (current_cert = store_context.current_cert)
          error = "#{error} Certificate subject: #{current_cert.subject}."
        end

        raise JWT::VerificationError, error
      end
    end

    private

    def build_store(root_certificates, crls)
      store = OpenSSL::X509::Store.new
      store.purpose = OpenSSL::X509::PURPOSE_ANY
      store.flags = OpenSSL::X509::V_FLAG_CRL_CHECK | OpenSSL::X509::V_FLAG_CRL_CHECK_ALL
      root_certificates.each { |certificate| store.add_cert(certificate) }
      crls&.each { |crl| store.add_crl(crl) }
      store
    end

    def parse_certificates(x5c_header_or_certificates)
      if x5c_header_or_certificates.all? { |obj| obj.is_a?(OpenSSL::X509::Certificate) }
        x5c_header_or_certificates
      else
        x5c_header_or_certificates.map do |encoded|
          OpenSSL::X509::Certificate.new(::JWT::Base64.url_decode(encoded))
        end
      end
    end
  end
end
