# == Schema Information
#
# Table name: account_saml_settings
#
#  id                      :bigint           not null, primary key
#  attribute_mappings      :json
#  certificate             :text
#  certificate_fingerprint :string
#  enabled                 :boolean          default(FALSE), not null
#  enforced_sso            :boolean          default(FALSE), not null
#  role_mappings           :json
#  sso_url                 :string
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  account_id              :bigint           not null
#  sp_entity_id            :string
#
# Indexes
#
#  index_account_saml_settings_on_account_id  (account_id)
#
class AccountSamlSettings < ApplicationRecord
  belongs_to :account

  validates :account_id, presence: true
  validates :sso_url, presence: true, if: :enabled?
  validates :certificate, presence: true, if: :enabled?
  validates :sp_entity_id, presence: true, if: :enabled?

  before_save :generate_certificate_fingerprint, if: :certificate_changed?

  scope :enabled, -> { where(enabled: true) }

  def saml_enabled?
    enabled && sso_url.present? && certificate_fingerprint.present?
  end

  def sp_entity_id_or_default
    sp_entity_id.presence || "#{installation_name}-#{account_id}".downcase
  end

  private

  def installation_name
    GlobalConfigService.load('INSTALLATION_NAME', 'Chatwoot')
  end

  def generate_certificate_fingerprint
    return unless certificate.present?

    begin
      cert = OpenSSL::X509::Certificate.new(certificate)
      self.certificate_fingerprint = OpenSSL::Digest::SHA256.new(cert.to_der).hexdigest.upcase.scan(/.{2}/).join(':')
    rescue OpenSSL::X509::CertificateError => e
      Rails.logger.error "Failed to parse SAML certificate: #{e.message}"
      errors.add(:certificate, 'is not a valid X.509 certificate')
      throw(:abort)
    end
  end
end
