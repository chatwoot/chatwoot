class Saml::IdpMetadataService
  class Error < StandardError; end

  MAX_METADATA_BYTES = 1.megabyte
  READ_TIMEOUT = 5

  def initialize(metadata_url)
    @metadata_url = metadata_url
  end

  def perform
    metadata = OneLogin::RubySaml::IdpMetadataParser.new.parse_to_hash(
      fetch_metadata, sso_binding: [OneLogin::RubySaml::Utils::BINDINGS[:redirect]]
    )
    certificates = Array(metadata[:idp_cert_multi]&.dig(:signing))
    if metadata[:idp_sso_service_url].blank? || metadata[:idp_entity_id].blank? || certificates.empty?
      raise Error, 'metadata has no redirect SSO URL, entity ID or signing certificate'
    end

    {
      sso_url: metadata[:idp_sso_service_url],
      idp_entity_id: metadata[:idp_entity_id],
      certificate: certificates.map { |certificate| validated_certificate(certificate) }.join("\n")
    }
  rescue SafeFetch::Error, URI::InvalidURIError, REXML::ParseException, ArgumentError, OpenSSL::X509::CertificateError => e
    raise Error, e.message
  end

  private

  # Each certificate is parsed on its own, because ruby-saml parses every entry when it validates a response.
  def validated_certificate(certificate)
    pem = OneLogin::RubySaml::Utils.format_cert(certificate)
    OpenSSL::X509::Certificate.new(pem)
    pem
  end

  def fetch_metadata
    # Chatwoot does not check the metadata signature, so only TLS protects the certificates it returns
    raise Error, 'metadata URL must use HTTPS' unless URI.parse(@metadata_url).is_a?(URI::HTTPS)

    SafeFetch.fetch(@metadata_url, validate_content_type: false, max_bytes: MAX_METADATA_BYTES, read_timeout: READ_TIMEOUT) do |result|
      result.tempfile.read
    end
  end
end
