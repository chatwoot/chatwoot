# frozen_string_literal: true

class ContactEmail < ApplicationRecord
  belongs_to :account
  belongs_to :contact

  before_validation :normalize_email

  validates :email, presence: true,
                    format: { with: Devise.email_regexp }
  validates :email, uniqueness: { scope: :account_id, case_sensitive: false }
  validate :account_matches_contact
  validate :email_not_used_as_primary

  private

  def normalize_email
    self.email = email.to_s.strip.downcase.presence
  end

  def account_matches_contact
    return if contact.blank? || account.blank? || contact.account_id == account_id

    errors.add(:account, :invalid)
  end

  def email_not_used_as_primary
    return if email.blank? || account_id.blank?
    return unless Contact.where(account_id: account_id).exists?(['LOWER(email) = ?', email])

    errors.add(:email, :taken)
  end
end
