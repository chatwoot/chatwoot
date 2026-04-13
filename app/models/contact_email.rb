class ContactEmail < ApplicationRecord
  belongs_to :account
  belongs_to :contact

  scope :primary, -> { where(primary: true) }

  before_validation :normalize_email

  validates :email, presence: true,
                    uniqueness: { scope: :account_id, case_sensitive: false },
                    format: { with: Devise.email_regexp, message: I18n.t('errors.contacts.email.invalid') }
  validates :primary, uniqueness: { scope: :contact_id }, if: :primary?
  validate :contact_belongs_to_account

  private

  def normalize_email
    self.email = email&.downcase
  end

  def contact_belongs_to_account
    return if contact.blank? || account.blank?
    return if contact.account_id == account_id

    errors.add(:contact, :invalid)
  end
end
