# == Schema Information
#
# Table name: account_whatsapp_settings
#
#  id               :bigint           not null, primary key
#  api_version      :string           default("v22.0")
#  app_secret       :string
#  verify_token     :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  account_id       :bigint           not null
#  app_id           :string
#  configuration_id :string
#
# Indexes
#
#  index_account_whatsapp_settings_on_account_id  (account_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class AccountWhatsappSettings < ApplicationRecord
  belongs_to :account

  validates :account_id, presence: true, uniqueness: true
  validates :app_id, presence: true
  validates :app_secret, presence: true
  validates :configuration_id, presence: true

  before_validation :set_defaults

  def whatsapp_configured?
    app_id.present? && app_secret.present? && configuration_id.present?
  end

  # Generate a default verify token if not provided
  def ensure_verify_token
    self.verify_token ||= SecureRandom.hex(32)
  end

  private

  def set_defaults
    self.api_version ||= 'v22.0'
    ensure_verify_token
  end
end
