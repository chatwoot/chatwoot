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
      certificate: certificates.map { |certificate| OneLogin::RubySaml::Utils.format_cert(certificate) }.join("\n")
    }
  rescue SafeFetch::Error, REXML::ParseException, ArgumentError => e
    raise Error, e.message
  end

  private

  def fetch_metadata
    SafeFetch.fetch(@metadata_url, validate_content_type: false, max_bytes: MAX_METADATA_BYTES, read_timeout: READ_TIMEOUT) do |result|
      result.tempfile.read
    end
  end
end
