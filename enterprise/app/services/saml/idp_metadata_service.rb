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
    # AccountSamlSettings validates these values, so missing fields and malformed certificates are rejected there
    certificates = Array(metadata[:idp_cert_multi]&.dig(:signing))

    {
      sso_url: metadata[:idp_sso_service_url],
      idp_entity_id: metadata[:idp_entity_id],
      signing_certificates: certificates.map { |certificate| OneLogin::RubySaml::Utils.format_cert(certificate) }
    }
  rescue SafeFetch::Error, URI::InvalidURIError, REXML::ParseException, ArgumentError => e
    raise Error, e.message
  end

  private

  def fetch_metadata
    # Chatwoot does not check the metadata signature, so only TLS protects the certificates it returns
    raise Error, 'metadata URL must use HTTPS' unless URI.parse(@metadata_url).is_a?(URI::HTTPS)

    SafeFetch.fetch(@metadata_url, validate_content_type: false, max_bytes: MAX_METADATA_BYTES, read_timeout: READ_TIMEOUT) do |result|
      result.tempfile.read
    end
  end
end
