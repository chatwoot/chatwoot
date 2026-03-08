# == Schema Information
#
# Table name: account_calendly_settings
#
#  id                       :bigint           not null, primary key
#  access_token             :string
#  enabled                  :boolean          default(FALSE), not null
#  organization_uri         :string
#  scheduling_url           :string
#  user_uri                 :string
#  webhook_signing_key      :string
#  webhook_subscription_uri :string
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  account_id               :bigint           not null
#
# Indexes
#
#  index_account_calendly_settings_on_account_id  (account_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class AccountCalendlySettings < ApplicationRecord
  belongs_to :account

  encrypts :access_token, deterministic: true if Chatwoot.encryption_configured?

  validates :account_id, presence: true, uniqueness: true
  validates :access_token, presence: true, if: :enabled?

  def calendly_configured?
    enabled? && access_token.present?
  end
end
