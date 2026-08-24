# == Schema Information
#
# Table name: account_saml_settings
#
#  id             :bigint           not null, primary key
#  certificate    :text
#  role_mappings  :json
#  sls_url        :string
#  sp_certificate :text
#  sp_private_key :text
#  sso_url        :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  account_id     :bigint           not null
#  idp_entity_id  :string
#  sp_entity_id   :string
#
# Indexes
#
#  index_account_saml_settings_on_account_id  (account_id)
#
class AccountSamlSettings < ApplicationRecord
  SINGLE_LOGOUT_SIGNED_ID_PURPOSE = :saml_single_logout
  SP_CERTIFICATE_VALIDITY = 10.years

  belongs_to :account

  encrypts :sp_private_key if Chatwoot.encryption_configured?

  validates :account_id, presence: true
  validates :sso_url, presence: true
  validates :certificate, presence: true
  validates :idp_entity_id, presence: true
  validates :sls_url, format: URI::DEFAULT_PARSER.make_regexp(%w[http https]), allow_blank: true
  validate :certificate_must_be_valid_x509
  validate :sp_signing_credentials_must_match, if: :single_logout_configured?

  before_validation :set_sp_entity_id, if: :sp_entity_id_needs_generation?
  before_validation :set_sp_signing_credentials, if: :sp_signing_credentials_need_generation?

  after_create_commit :update_account_users_provider
  after_destroy_commit :reset_account_users_provider

  def saml_enabled?
    sso_url.present? && certificate.present?
  end

  def single_logout_configured?
    sls_url.present?
  end

  def sp_sls_url
    return if new_record?

    base_url = GlobalConfigService.load('FRONTEND_URL', 'http://localhost:3000')
    "#{base_url}/saml/slo/#{signed_id(purpose: SINGLE_LOGOUT_SIGNED_ID_PURPOSE)}"
  end

  def certificate_fingerprint
    return nil if certificate.blank?

    begin
      cert = OpenSSL::X509::Certificate.new(certificate)
      OpenSSL::Digest::SHA1.new(cert.to_der).hexdigest
                           .upcase.gsub(/(.{2})(?=.)/, '\1:')
    rescue OpenSSL::X509::CertificateError
      nil
    end
  end

  private

  def set_sp_signing_credentials
    key = OpenSSL::PKey::RSA.new(2048)
    certificate = build_sp_certificate(key)

    self.sp_private_key = key.to_pem
    self.sp_certificate = certificate.to_pem
  end

  def build_sp_certificate(key)
    certificate = OpenSSL::X509::Certificate.new
    certificate.version = 2
    certificate.serial = SecureRandom.random_number(2**159)
    certificate.subject = OpenSSL::X509::Name.new([['CN', installation_name, OpenSSL::ASN1::UTF8STRING]])
    certificate.issuer = certificate.subject
    certificate.public_key = key.public_key
    certificate.not_before = 1.minute.ago
    certificate.not_after = SP_CERTIFICATE_VALIDITY.from_now
    add_sp_certificate_extensions(certificate)
    certificate.sign(key, OpenSSL::Digest.new('SHA256'))
    certificate
  end

  def add_sp_certificate_extensions(certificate)
    extension_factory = OpenSSL::X509::ExtensionFactory.new
    extension_factory.subject_certificate = certificate
    extension_factory.issuer_certificate = certificate
    certificate.add_extension(extension_factory.create_extension('basicConstraints', 'CA:FALSE', true))
    certificate.add_extension(extension_factory.create_extension('keyUsage', 'digitalSignature', true))
    certificate.add_extension(extension_factory.create_extension('subjectKeyIdentifier', 'hash'))
  end

  def sp_signing_credentials_need_generation?
    single_logout_configured? && (sp_private_key.blank? || sp_certificate.blank?)
  end

  def sp_signing_credentials_must_match
    key = OpenSSL::PKey::RSA.new(sp_private_key)
    certificate = OpenSSL::X509::Certificate.new(sp_certificate)
    return if certificate.check_private_key(key)

    errors.add(:sp_certificate, I18n.t('profile.account_saml_settings.invalid_sp_signing_credentials'))
  rescue OpenSSL::PKey::PKeyError, OpenSSL::X509::CertificateError
    errors.add(:sp_certificate, I18n.t('profile.account_saml_settings.invalid_sp_signing_credentials'))
  end

  def set_sp_entity_id
    base_url = GlobalConfigService.load('FRONTEND_URL', 'http://localhost:3000')
    self.sp_entity_id = "#{base_url}/saml/sp/#{account_id}"
  end

  def sp_entity_id_needs_generation?
    sp_entity_id.blank?
  end

  def installation_name
    GlobalConfigService.load('INSTALLATION_NAME', 'Chatwoot').to_s.first(64)
  end

  def update_account_users_provider
    Saml::UpdateAccountUsersProviderJob.perform_later(account_id, 'saml')
  end

  def reset_account_users_provider
    Saml::UpdateAccountUsersProviderJob.perform_later(account_id, 'email')
  end

  def certificate_must_be_valid_x509
    return if certificate.blank?

    OpenSSL::X509::Certificate.new(certificate)
  rescue OpenSSL::X509::CertificateError
    errors.add(:certificate, I18n.t('errors.account_saml_settings.invalid_certificate'))
  end
end
