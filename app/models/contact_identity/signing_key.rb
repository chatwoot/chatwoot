# == Schema Information
#
# Table name: contact_identity_signing_keys
#
#  id         :bigint           not null, primary key
#  secret     :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  inbox_id   :bigint           not null
#
# Indexes
#
#  index_contact_identity_signing_keys_on_inbox_id  (inbox_id)
#
class ContactIdentity::SigningKey < ApplicationRecord
  # HS256 needs a key of at least 32 bytes.
  SECRET_LENGTH = 64
  # Two keys let a business move to a new key before it removes the old one.
  MAX_KEYS_PER_INBOX = 2

  self.table_name = 'contact_identity_signing_keys'

  belongs_to :inbox

  has_secure_token :secret, length: SECRET_LENGTH
  encrypts :secret if Chatwoot.encryption_configured?

  validate :inbox_has_room_for_key, on: :create

  private

  def inbox_has_room_for_key
    return if inbox.blank?
    return if inbox.contact_identity_signing_keys.count < MAX_KEYS_PER_INBOX

    errors.add(:base, I18n.t('errors.contact_identity.signing_key.limit_reached', limit: MAX_KEYS_PER_INBOX))
  end
end
