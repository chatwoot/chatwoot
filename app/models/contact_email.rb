# frozen_string_literal: true

class ContactEmail < ApplicationRecord
  belongs_to :contact
  belongs_to :account

  before_validation :normalize_email
  before_destroy :ensure_contact_has_primary_after_destroy

  validates :email, presence: true,
                    uniqueness: { scope: :account_id, case_sensitive: false },
                    format: { with: Devise.email_regexp, message: I18n.t('errors.contacts.email.invalid') }
  validates :primary, inclusion: { in: [true, false] }
  validate :account_matches_contact
  validate :contact_has_single_primary_state

  private

  def normalize_email
    self.email = email.to_s.strip.downcase.presence
  end

  def account_matches_contact
    return if contact.blank? || account.blank? || contact.account_id == account_id

    errors.add(:account, :invalid)
  end

  def contact_has_single_primary_state
    return if contact.blank?

    sibling_scope = contact.contact_emails.where.not(id: id)
    primary_count = sibling_scope.where(primary: true).count + (primary? ? 1 : 0)

    errors.add(:primary, :taken) if primary? && sibling_scope.exists?(primary: true)
    return if primary_count == 1

    errors.add(:contact, I18n.t('errors.contacts.email.invalid'))
  end

  def ensure_contact_has_primary_after_destroy
    return if destroyed_by_association.present? || contact.blank?

    sibling_scope = contact.contact_emails.where.not(id: id)
    return if sibling_scope.count.zero? || sibling_scope.where(primary: true).count == 1

    errors.add(:base, I18n.t('errors.contacts.email.invalid'))
    throw(:abort)
  end
end
