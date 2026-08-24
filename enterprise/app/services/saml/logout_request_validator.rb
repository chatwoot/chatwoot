class Saml::LogoutRequestValidator
  class InvalidRequest < StandardError
    attr_reader :request_id

    def initialize(message, request_id: nil)
      @request_id = request_id
      super(message)
    end
  end

  PROTOCOL_NAMESPACE = 'urn:oasis:names:tc:SAML:2.0:protocol'.freeze
  SIGNATURE_NAMESPACE = 'http://www.w3.org/2000/09/xmldsig#'.freeze
  MAX_REQUEST_AGE = 5.minutes
  ALLOWED_CLOCK_DRIFT = 1.minute
  # Cache eviction can permit a replay only while the original request remains valid within this age-plus-drift window.
  REPLAY_TTL = (MAX_REQUEST_AGE + ALLOWED_CLOCK_DRIFT).to_i
  MAX_ENCODED_REQUEST_SIZE = 100.kilobytes
  MAX_XML_REQUEST_SIZE = 64.kilobytes

  ALLOWED_SIGNATURE_METHODS = [
    XMLSecurity::Document::RSA_SHA256,
    XMLSecurity::Document::RSA_SHA384,
    XMLSecurity::Document::RSA_SHA512
  ].freeze
  ALLOWED_DIGEST_METHODS = [
    XMLSecurity::Document::SHA256,
    XMLSecurity::Document::SHA384,
    XMLSecurity::Document::SHA512
  ].freeze
  ALLOWED_TRANSFORMS = [
    XMLSecurity::Document::ENVELOPED_SIG,
    XMLSecurity::BaseDocument::C14N
  ].freeze

  def initialize(saml_settings:, encoded_request:, ruby_saml_settings:)
    @saml_settings = saml_settings
    @encoded_request = encoded_request
    @ruby_saml_settings = ruby_saml_settings
  end

  def perform
    parse_request!
    validate_signed_root!
    validate_xml_signature!
    validate_saml_request!
    validate_destination!
    validate_issue_instant!
    logout_request
  end

  private

  attr_reader :saml_settings, :encoded_request, :ruby_saml_settings, :logout_request, :xml_document

  def parse_request!
    raise InvalidRequest, 'SAMLRequest is missing' if encoded_request.blank?
    raise InvalidRequest, 'SAMLRequest is too large' unless valid_encoded_size?

    decoded_request = Base64.strict_decode64(encoded_request.gsub(/\s/, ''))
    raise InvalidRequest, 'SAMLRequest is too large' if decoded_request.bytesize > MAX_XML_REQUEST_SIZE

    @xml_document = XMLSecurity::BaseDocument.safe_load_xml(decoded_request)
    @logout_request = OneLogin::RubySaml::SloLogoutrequest.new(
      decoded_request,
      settings: ruby_saml_settings,
      allowed_clock_drift: ALLOWED_CLOCK_DRIFT
    )
  rescue StandardError => e
    raise if e.is_a?(InvalidRequest)

    raise InvalidRequest, e.message
  end

  def valid_encoded_size?
    encoded_request.is_a?(String) && encoded_request.bytesize <= MAX_ENCODED_REQUEST_SIZE
  end

  def validate_signed_root!
    root = xml_document.root
    valid_root = root&.name == 'LogoutRequest' && root&.namespace&.href == PROTOCOL_NAMESPACE
    raise InvalidRequest, 'SAML message is not a LogoutRequest' unless valid_root

    signature = root_signature!(root)
    validate_signature_algorithms!(signature)
    validate_signature_reference!(root, signature)
  end

  def root_signature!(root)
    root_signatures = root.xpath('./ds:Signature', 'ds' => SIGNATURE_NAMESPACE)
    all_signatures = root.xpath('.//ds:Signature', 'ds' => SIGNATURE_NAMESPACE)
    return root_signatures.first if root_signatures.one? && all_signatures.one?

    raise InvalidRequest, 'LogoutRequest must contain one root XML signature'
  end

  def validate_signature_reference!(root, signature)
    references = signature.xpath('./ds:SignedInfo/ds:Reference', 'ds' => SIGNATURE_NAMESPACE)
    request_id = root['ID']
    signed_id = references.first&.[]('URI')&.delete_prefix('#')
    matching_nodes = request_id.present? ? xml_document.xpath('//*[@ID=$id]', nil, id: request_id) : []
    validation_results = [references.one?, request_id.present?, signed_id == request_id, matching_nodes.one?, matching_nodes.first == root]
    return if validation_results.all?

    raise InvalidRequest, 'XML signature must reference the LogoutRequest root'
  end

  def validate_signature_algorithms!(signature)
    canonicalization_method = signature.at_xpath(
      './ds:SignedInfo/ds:CanonicalizationMethod', 'ds' => SIGNATURE_NAMESPACE
    )&.[]('Algorithm')
    signature_method = signature.at_xpath('./ds:SignedInfo/ds:SignatureMethod', 'ds' => SIGNATURE_NAMESPACE)&.[]('Algorithm')
    digest_method = signature.at_xpath('./ds:SignedInfo/ds:Reference/ds:DigestMethod', 'ds' => SIGNATURE_NAMESPACE)&.[]('Algorithm')
    transforms = signature.xpath(
      './ds:SignedInfo/ds:Reference/ds:Transforms/ds:Transform', 'ds' => SIGNATURE_NAMESPACE
    ).pluck('Algorithm')
    validation_results = [
      canonicalization_method == XMLSecurity::BaseDocument::C14N,
      ALLOWED_SIGNATURE_METHODS.include?(signature_method),
      ALLOWED_DIGEST_METHODS.include?(digest_method),
      transforms == ALLOWED_TRANSFORMS
    ]
    return if validation_results.all?

    raise InvalidRequest, 'LogoutRequest uses an unsupported signature algorithm'
  end

  def validate_xml_signature!
    signed_document = XMLSecurity::SignedDocument.new(logout_request.request)
    certificate = OpenSSL::X509::Certificate.new(saml_settings.certificate)
    valid_signature = signed_document.validate_document_with_cert(certificate, false)
    return if valid_signature && signed_document.signed_element_id == logout_request.id

    raise InvalidRequest, 'Invalid LogoutRequest signature'
  rescue OneLogin::RubySaml::ValidationError, OpenSSL::X509::CertificateError => e
    raise InvalidRequest, e.message
  end

  def validate_saml_request!
    # ruby-saml skips signature validation without Redirect-binding query parameters.
    # validate_xml_signature! must always run before this call.
    raise InvalidRequest.new(logout_request.errors.join(', '), request_id: logout_request.id) unless logout_request.is_valid?
    return if logout_request.issuer == saml_settings.idp_entity_id

    raise InvalidRequest.new('LogoutRequest Issuer does not match this tenant', request_id: logout_request.id)
  end

  def validate_destination!
    return if xml_document.root['Destination'] == saml_settings.sp_sls_url

    raise InvalidRequest.new('LogoutRequest Destination does not match this tenant', request_id: logout_request.id)
  end

  def validate_issue_instant!
    issue_instant = Time.iso8601(xml_document.root['IssueInstant'])
    earliest = Time.current - MAX_REQUEST_AGE
    latest = Time.current + ALLOWED_CLOCK_DRIFT
    return if issue_instant.between?(earliest, latest)

    raise InvalidRequest.new('LogoutRequest IssueInstant is outside the accepted time window', request_id: logout_request.id)
  rescue ArgumentError, TypeError
    raise InvalidRequest.new('LogoutRequest IssueInstant is invalid', request_id: logout_request.id)
  end
end
