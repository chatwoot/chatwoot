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

  after_create_commit :update_account_users_provider
  after_destroy_commit :reset_account_users_provider

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

  def update_account_users_provider
    UpdateAccountUsersProviderJob.perform_later(account_id, 'saml')
  end

  def reset_account_users_provider
    UpdateAccountUsersProviderJob.perform_later(account_id, 'email')
  end
end
