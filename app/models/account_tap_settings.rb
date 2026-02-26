# == Schema Information
#
# Table name: account_tap_settings
#
#  id         :bigint           not null, primary key
#  enabled    :boolean          default(FALSE), not null
#  secret_key :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#
# Indexes
#
#  index_account_tap_settings_on_account_id  (account_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class AccountTapSettings < ApplicationRecord
  belongs_to :account

  encrypts :secret_key, deterministic: true if Chatwoot.encryption_configured?

  validates :account_id, presence: true, uniqueness: true
  validates :secret_key, presence: true, if: :enabled?

  def tap_configured?
    enabled? && secret_key.present?
  end
end
