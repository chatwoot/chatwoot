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

  # Admins compare this with the IdP to confirm a refresh picked up a rotated certificate.
  # When the IdP lists several certificates, it shows the newest one, the same certificate certificate_expiring? uses.
  def certificate_fingerprint
    return nil if certificate.blank?

    begin
      OpenSSL::Digest::SHA1.new(newest_certificate.to_der).hexdigest
                           .upcase.gsub(/(.{2})(?=.)/, '\1:')
    rescue OpenSSL::X509::CertificateError
      nil
    end
  end

  # Metadata can list more than one signing certificate while the IdP rotates its key.
  def signing_certificates
    parsed_certificates.map(&:to_pem)
  end

  def signing_certificates=(certificates)
    self.certificate = certificates.join("\n")
  end

  def refresh_metadata_if_needed
    return if metadata_url.blank? || !certificate_expiring? || metadata_refreshed_at&.after?(METADATA_REFRESH_INTERVAL.ago)

    # Claim the refresh before fetching, so concurrent logins use the stored values instead of all waiting on the IdP
    claimed = self.class.where(id: id)
                  .where('metadata_refreshed_at IS NULL OR metadata_refreshed_at < ?', METADATA_REFRESH_INTERVAL.ago)
                  .update_all(metadata_refreshed_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
    return if claimed.zero? || refresh_metadata

    Rails.logger.warn "SAML metadata refresh failed for account #{account_id}: #{errors.full_messages.to_sentence}"
    # The login that called this uses these values, so drop the rejected ones and keep the stored ones
    restore_attributes
  end

  # Reads the metadata again right away, for the refresh button in the settings form
  def refresh_metadata
    if metadata_url.blank?
      errors.add(:metadata_url, :blank)
      return false
    end

    assign_idp_metadata
    errors.empty? && save
  end

  private

  def certificate_expiring?
    newest_certificate.not_after < CERTIFICATE_EXPIRY_WINDOW.from_now
  end

  # During a rotation the IdP lists the outgoing and incoming certificates in no fixed order, so the newest is the
  # one picked by expiry date. An expired certificate the IdP still lists then does not keep triggering refreshes.
  def newest_certificate
    parsed_certificates.max_by(&:not_after)
  end

  # Reads every certificate in the stored value, and raises if any block is malformed or none is found
  def parsed_certificates
    OpenSSL::X509::Certificate.load(certificate.to_s)
  end

  def assign_idp_metadata
    assign_attributes(Saml::IdpMetadataService.new(metadata_url).perform.merge(metadata_refreshed_at: Time.current))
  rescue Saml::IdpMetadataService::Error => e
    errors.add(:metadata_url, I18n.t("errors.account_saml_settings.metadata_url.#{e.reason}"))
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

    # ruby-saml parses every block when the value holds more than one certificate
    parsed_certificates
  rescue OpenSSL::X509::CertificateError
    errors.add(:certificate, I18n.t('errors.account_saml_settings.invalid_certificate'))
  end
end
