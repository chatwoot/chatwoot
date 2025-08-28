# == Schema Information
#
# Table name: account_saml_settings
#
#  id                 :bigint           not null, primary key
#  attribute_mappings :json
#  certificate        :text
#  enforced_sso       :boolean          default(FALSE), not null
#  role_mappings      :json
#  sso_url            :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  account_id         :bigint           not null
#  sp_entity_id       :string
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

  private

  def installation_name
    GlobalConfigService.load('INSTALLATION_NAME', 'Chatwoot')
  end
end
