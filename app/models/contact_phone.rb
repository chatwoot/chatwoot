# frozen_string_literal: true

class ContactPhone < ApplicationRecord
  belongs_to :account
  belongs_to :contact

  before_validation :normalize_phone_number

  validates :phone_number, presence: true
  validates :phone_number, format: { with: /\+[1-9]\d{1,14}\z/ }
  validates :phone_number, uniqueness: { scope: :account_id }
  validate :account_matches_contact
  validate :phone_not_used_as_primary

  private

  def normalize_phone_number
    self.phone_number = phone_number.to_s.strip.presence
  end

  def account_matches_contact
    return if contact.blank? || account.blank? || contact.account_id == account_id

    errors.add(:account, :invalid)
  end

  def phone_not_used_as_primary
    return if phone_number.blank? || account_id.blank?
    return unless Contact.exists?(account_id: account_id, phone_number: phone_number)

    errors.add(:phone_number, :taken)
  end
end
