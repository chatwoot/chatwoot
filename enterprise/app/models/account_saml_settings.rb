class AccountSamlSettings < ApplicationRecord
  belongs_to :account
  has_many :saml_role_mappings, dependent: :destroy

  validates :account_id, presence: true
  validates :sso_url, presence: true, if: :enabled?
  validates :certificate_fingerprint, presence: true, if: :enabled?
  validates :sp_entity_id, presence: true, if: :enabled?

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
end
