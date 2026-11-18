class Saml::IdpMetadataService
  # The reason picks the message shown to admins, from errors.account_saml_settings.metadata_url.
  # The message keeps the underlying cause, which can include host names and IP addresses, so admins never see it.
  class Error < StandardError
    attr_reader :reason

    def initialize(reason, message = reason.to_s)
      @reason = reason
      super(message)
    end
  end

  MAX_METADATA_BYTES = 1.megabyte
  READ_TIMEOUT = 5
  FETCH_ERROR_REASONS = {
    URI::InvalidURIError => :invalid_url,
    SafeFetch::InvalidUrlError => :invalid_url,
    SafeFetch::UnsafeUrlError => :blocked_address,
    SafeFetch::HttpError => :http_error,
    SafeFetch::FetchError => :unreachable,
    SafeFetch::FileTooLargeError => :too_large
  }.freeze

  def initialize(metadata_url)
    @metadata_url = metadata_url
  end

  def perform
    metadata = parse_metadata(fetch_metadata)
    # AccountSamlSettings validates these values, so missing fields and malformed certificates are rejected there
    certificates = Array(metadata[:idp_cert_multi]&.dig(:signing))

    {
      sso_url: metadata[:idp_sso_service_url],
      idp_entity_id: metadata[:idp_entity_id],
      signing_certificates: certificates.map { |certificate| OneLogin::RubySaml::Utils.format_cert(certificate) }
    }
  end

  private

  def fetch_metadata
    # Chatwoot does not check the metadata signature, so only TLS protects the certificates it returns.
    # This checks only the entered URL. SafeFetch follows redirects, including to HTTP, and has no option to stop that.
    raise Error, :invalid_url unless URI.parse(@metadata_url).is_a?(URI::HTTPS)

    SafeFetch.fetch(@metadata_url, validate_content_type: false, max_bytes: MAX_METADATA_BYTES, read_timeout: READ_TIMEOUT) do |result|
      result.tempfile.read
    end
  rescue *FETCH_ERROR_REASONS.keys => e
    raise Error.new(FETCH_ERROR_REASONS.fetch(e.class), e.message)
  end

  # ruby-saml raises ArgumentError when the document has no IDPSSODescriptor.
  # It raises CertificateError when it fingerprints a lone signing certificate that OpenSSL cannot read.
  def parse_metadata(xml)
    OneLogin::RubySaml::IdpMetadataParser.new.parse_to_hash(xml, sso_binding: [OneLogin::RubySaml::Utils::BINDINGS[:redirect]])
  rescue REXML::ParseException, ArgumentError, OpenSSL::X509::CertificateError => e
    raise Error.new(:not_metadata, e.message)
  end
end
