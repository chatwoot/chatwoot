# == Schema Information
#
# Table name: storefront_tokens
#
#  id              :bigint           not null, primary key
#  expires_at      :datetime
#  last_used_at    :datetime
#  token           :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#  contact_id      :bigint           not null
#  conversation_id :bigint
#
# Indexes
#
#  index_storefront_tokens_on_account_id                 (account_id)
#  index_storefront_tokens_on_account_id_and_contact_id  (account_id,contact_id)
#  index_storefront_tokens_on_contact_id                 (contact_id)
#  index_storefront_tokens_on_conversation_id            (conversation_id)
#  index_storefront_tokens_on_token                      (token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (contact_id => contacts.id)
#  fk_rails_...  (conversation_id => conversations.id)
#
class StorefrontToken < ApplicationRecord
  belongs_to :account
  belongs_to :contact
  belongs_to :conversation, optional: true

  validates :token, presence: true, uniqueness: true

  before_validation :generate_token, on: :create

  scope :active, -> { where('expires_at IS NULL OR expires_at > ?', Time.current) }

  def expired?
    expires_at.present? && expires_at < Time.current
  end

  def touch_last_used!
    # rubocop:disable Rails/SkipsModelValidations
    update_column(:last_used_at, Time.current)
    # rubocop:enable Rails/SkipsModelValidations
  end

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(32)
  end
end
