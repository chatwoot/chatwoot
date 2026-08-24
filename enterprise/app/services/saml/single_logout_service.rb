class Saml::SingleLogoutService
  class Error < StandardError
    attr_reader :request_id

    def initialize(message, request_id: nil)
      @request_id = request_id
      super(message)
    end
  end

  class ConfigurationError < Error; end
  class InvalidRequest < Error; end
  class ReplayDetected < Error; end
  class UnknownPrincipal < Error; end

  NAME_ID_FORMAT_EMAIL = 'urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress'.freeze
  MAX_RELAY_STATE_SIZE = 80
  REPLAY_TTL = Saml::LogoutRequestValidator::REPLAY_TTL
  STATUS_SUCCESS = 'urn:oasis:names:tc:SAML:2.0:status:Success'.freeze
  STATUS_REQUESTER = 'urn:oasis:names:tc:SAML:2.0:status:Requester'.freeze

  def initialize(saml_settings:, encoded_request:, relay_state: nil)
    @saml_settings = saml_settings
    @encoded_request = encoded_request
    @relay_state = relay_state
  end

  def perform
    validate_configuration!
    validate_relay_state!
    @logout_request = validate_logout_request!
    claim_request_id!
    revoke_user_sessions!
    logout_request.id
  end

  def logout_response_url(request_id:, status_code:, message:)
    validate_configuration!
    OneLogin::RubySaml::SloLogoutresponse.new.create(
      ruby_saml_settings,
      request_id,
      message,
      response_parameters,
      status_code
    )
  end

  private

  attr_reader :saml_settings, :encoded_request, :relay_state, :logout_request, :replay_claim_token

  def validate_configuration!
    raise ConfigurationError, 'SAML single logout is not configured' unless signing_credentials_present?

    idp_certificate = OpenSSL::X509::Certificate.new(saml_settings.certificate)
    sp_key = OpenSSL::PKey::RSA.new(saml_settings.sp_private_key)
    sp_certificate = OpenSSL::X509::Certificate.new(saml_settings.sp_certificate)
    return if valid_signing_credentials?(idp_certificate, sp_certificate, sp_key)

    raise ConfigurationError, 'SAML signing credentials are invalid or expired'
  rescue OpenSSL::PKey::PKeyError, OpenSSL::X509::CertificateError => e
    raise ConfigurationError, e.message
  end

  def signing_credentials_present?
    saml_settings.single_logout_configured? && saml_settings.sp_private_key.present? && saml_settings.sp_certificate.present?
  end

  def valid_signing_credentials?(idp_certificate, sp_certificate, sp_key)
    certificates = [idp_certificate, sp_certificate]
    certificates.all? { |certificate| OneLogin::RubySaml::Utils.is_cert_active(certificate) } &&
      sp_key.private? && sp_key.n.num_bits >= 2048 && sp_certificate.check_private_key(sp_key)
  end

  def validate_relay_state!
    return if relay_state.blank?
    return if relay_state.is_a?(String) && relay_state.bytesize <= MAX_RELAY_STATE_SIZE

    raise InvalidRequest, 'RelayState is too large'
  end

  def validate_logout_request!
    Saml::LogoutRequestValidator.new(
      saml_settings: saml_settings,
      encoded_request: encoded_request,
      ruby_saml_settings: ruby_saml_settings
    ).perform
  rescue Saml::LogoutRequestValidator::InvalidRequest => e
    raise InvalidRequest.new(e.message, request_id: e.request_id)
  end

  def claim_request_id!
    @replay_claim_token = SecureRandom.uuid
    claimed = Redis::Alfred.set(replay_key, replay_claim_token, nx: true, ex: REPLAY_TTL)
    return if claimed

    raise ReplayDetected.new('LogoutRequest has already been processed', request_id: logout_request.id)
  end

  def revoke_user_sessions!
    user = saml_user
    raise UnknownPrincipal.new('SAML subject does not match an account user', request_id: logout_request.id) unless user

    user.update!(tokens: {})
  rescue ActiveRecord::ActiveRecordError
    Redis::Alfred.delete_if_equals(replay_key, replay_claim_token)
    raise
  end

  def saml_user
    return unless logout_request.name_id_format == NAME_ID_FORMAT_EMAIL

    saml_settings.account.users.find_by(email: logout_request.name_id&.downcase, provider: 'saml')
  end

  def replay_key
    request_id_digest = Digest::SHA256.hexdigest(logout_request.id)
    "saml:single_logout:#{saml_settings.id}:#{request_id_digest}"
  end

  def response_parameters
    relay_state.present? ? { RelayState: relay_state } : {}
  end

  def ruby_saml_settings
    @ruby_saml_settings ||= OneLogin::RubySaml::Settings.new.tap do |settings|
      configure_identity_provider(settings)
      configure_service_provider(settings)
      configure_security(settings)
    end
  end

  def configure_identity_provider(settings)
    settings.idp_entity_id = saml_settings.idp_entity_id
    settings.idp_cert = saml_settings.certificate
    settings.idp_slo_service_url = saml_settings.sls_url
    settings.idp_slo_service_binding = :redirect
  end

  def configure_service_provider(settings)
    settings.sp_entity_id = saml_settings.sp_entity_id
    settings.certificate = saml_settings.sp_certificate
    settings.private_key = saml_settings.sp_private_key
    settings.compress_response = true
  end

  def configure_security(settings)
    settings.security[:logout_responses_signed] = true
    settings.security[:signature_method] = XMLSecurity::Document::RSA_SHA256
    settings.security[:digest_method] = XMLSecurity::Document::SHA256
  end
end
