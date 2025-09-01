# == Schema Information
#
# Table name: account_saml_settings
#
#  id            :bigint           not null, primary key
#  certificate   :text
#  role_mappings :json
#  sso_url       :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :bigint           not null
#  sp_entity_id  :string
#
# Indexes
#
#  index_account_saml_settings_on_account_id  (account_id)
#
class AccountSamlSettings < ApplicationRecord
  belongs_to :account

  validates :account_id, presence: true
  validates :sso_url, presence: true
  validates :certificate, presence: true
  validates :sp_entity_id, presence: true

  def saml_enabled?
    sso_url.present? && certificate.present?
  end

  def sp_entity_id_or_default
    sp_entity_id.presence || "#{installation_name}-#{account_id}".downcase
  end

  def certificate_fingerprint
    return nil if certificate.blank?

    begin
      cert = OpenSSL::X509::Certificate.new(certificate)
      fingerprint = OpenSSL::Digest::SHA1.new(cert.to_der).to_s
      fingerprint.upcase.gsub(/(.{2})(?=.)/, '\1:')
    rescue OpenSSL::X509::CertificateError
      nil
    end
  end

  private

  def installation_name
    GlobalConfigService.load('INSTALLATION_NAME', 'Chatwoot')
  end
end
