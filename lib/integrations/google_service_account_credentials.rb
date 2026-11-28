module Integrations::GoogleServiceAccountCredentials
  REQUIRED_KEY_FIELDS = %w[client_email private_key].freeze
  CLIENT_KEY_FIELDS = (REQUIRED_KEY_FIELDS + %w[type project_id quota_project_id]).freeze
  SERVICE_ACCOUNT_FIELDS = (CLIENT_KEY_FIELDS + %w[client_id private_key_id]).freeze
  GOOGLE_FIELD_VALUES = {
    'auth_uri' => %w[https://accounts.google.com/o/oauth2/auth].freeze,
    'token_uri' => %w[https://oauth2.googleapis.com/token https://accounts.google.com/o/oauth2/token https://www.googleapis.com/oauth2/v4/token].freeze,
    'auth_provider_x509_cert_url' => %w[https://www.googleapis.com/oauth2/v1/certs].freeze,
    'universe_domain' => %w[googleapis.com].freeze
  }.freeze
  CLIENT_CERT_URL = %r{\Ahttps://www\.googleapis\.com/robot/v1/metadata/x509/[A-Za-z0-9_.+-]+(?:%40|@)[A-Za-z0-9.-]+\z}

  def self.for_client(credentials, fallback_project_id: nil)
    return unless valid_key?(credentials)

    project_id = credentials.fetch('project_id', fallback_project_id)
    return unless project_id.is_a?(String) && project_id.present?

    # Supply a project ID to avoid local discovery and let Google's SDK use its built-in authentication URLs.
    credentials.slice(*CLIENT_KEY_FIELDS).merge('project_id' => project_id)
  end

  def self.valid_key?(credentials)
    return false unless credentials.is_a?(Hash) && credentials['type'] == 'service_account'

    REQUIRED_KEY_FIELDS.all? { |field| credentials[field].present? } &&
      credentials.all? { |field, value| credential_field_valid?(field, value) }
  end

  def self.credential_field_valid?(field, value)
    return false unless value.is_a?(String)
    return true if SERVICE_ACCOUNT_FIELDS.include?(field)
    return CLIENT_CERT_URL.match?(value) if field == 'client_x509_cert_url'

    GOOGLE_FIELD_VALUES[field]&.include?(value)
  end
  private_class_method :valid_key?, :credential_field_valid?
end
