# == Schema Information
#
# Table name: account_payzah_settings
#
#  id         :bigint           not null, primary key
#  api_key    :string
#  enabled    :boolean          default(FALSE), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#
# Indexes
#
#  index_account_payzah_settings_on_account_id  (account_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class AccountPayzahSettings < ApplicationRecord
  belongs_to :account

  # Encrypt api_key when encryption is configured
  encrypts :api_key, deterministic: true if Chatwoot.encryption_configured?

  validates :account_id, presence: true, uniqueness: true
  validates :api_key, presence: true, if: :enabled?

  def payzah_configured?
    enabled? && api_key.present?
  end
end
