# == Schema Information
#
# Table name: account_saml_settings
#
#  id                    :bigint           not null, primary key
#  certificate           :text
#  metadata_refreshed_at :datetime
#  metadata_url          :string
#  role_mappings         :json
#  sso_url               :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  account_id            :bigint           not null
#  idp_entity_id         :string
#  sp_entity_id          :string
#
# Indexes
#
#  index_account_saml_settings_on_account_id  (account_id)
#
class AccountSamlSettings < ApplicationRecord
  # Some IdPs, such as ZITADEL, switch to a new certificate only minutes before the current one expires
  CERTIFICATE_EXPIRY_WINDOW = 15.minutes
  METADATA_REFRESH_INTERVAL = 5.minutes
  PEM_CERTIFICATE_PATTERN = /-----BEGIN CERTIFICATE-----.+?-----END CERTIFICATE-----/m

  belongs_to :account

  validates :account_id, presence: true
  validates :sso_url, presence: true
  validates :certificate, presence: true
  validates :idp_entity_id, presence: true
  validate :certificate_must_be_valid_x509

  before_validation :set_sp_entity_id, if: :sp_entity_id_needs_generation?
  before_validation :assign_idp_metadata, if: -> { metadata_url.present? && metadata_url_changed? }

  after_create_commit :update_account_users_provider
  after_destroy_commit :reset_account_users_provider

  def saml_enabled?
    sso_url.present? && certificate.present?
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

  # Metadata can list more than one signing certificate while the IdP rotates its key.
  def signing_certificates
    certificate.to_s.scan(PEM_CERTIFICATE_PATTERN)
  end

  def refresh_metadata
    return if metadata_url.blank? || !certificate_expiring? || metadata_refreshed_at&.after?(METADATA_REFRESH_INTERVAL.ago)

    # Claim the refresh before fetching, so concurrent logins use the stored values instead of all waiting on the IdP
    claimed = self.class.where(id: id)
                  .where('metadata_refreshed_at IS NULL OR metadata_refreshed_at < ?', METADATA_REFRESH_INTERVAL.ago)
                  .update_all(metadata_refreshed_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
    return if claimed.zero?

    update!(idp_metadata)
  rescue Saml::IdpMetadataService::Error, ActiveRecord::RecordInvalid => e
    Rails.logger.warn "SAML metadata refresh failed for account #{account_id}: #{e.message}"
    # The login that called this uses these values, so drop the rejected ones and keep the stored ones
    restore_attributes
  end

  private

  def certificate_expiring?
    signing_certificates.any? { |pem| OpenSSL::X509::Certificate.new(pem).not_after < CERTIFICATE_EXPIRY_WINDOW.from_now }
  end

  def idp_metadata
    Saml::IdpMetadataService.new(metadata_url).perform.merge(metadata_refreshed_at: Time.current)
  end

  def assign_idp_metadata
    assign_attributes(idp_metadata)
  rescue Saml::IdpMetadataService::Error
    errors.add(:metadata_url, I18n.t('errors.account_saml_settings.invalid_metadata_url'))
  end

  def set_sp_entity_id
    base_url = GlobalConfigService.load('FRONTEND_URL', 'http://localhost:3000')
    self.sp_entity_id = "#{base_url}/saml/sp/#{account_id}"
  end

  def sp_entity_id_needs_generation?
    sp_entity_id.blank?
  end

  def installation_name
    GlobalConfigService.load('INSTALLATION_NAME', 'Chatwoot')
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
    # ruby-saml parses every block when the value holds more than one certificate
    signing_certificates.each { |pem| OpenSSL::X509::Certificate.new(pem) }
  rescue OpenSSL::X509::CertificateError
    errors.add(:certificate, I18n.t('errors.account_saml_settings.invalid_certificate'))
  end
end
