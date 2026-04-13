# == Schema Information
#
# Table name: contact_emails
#
#  id         :bigint           not null, primary key
#  email      :string           not null
#  primary    :boolean          default(FALSE), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#  contact_id :bigint           not null
#
# Indexes
#
#  index_contact_emails_on_account_id                 (account_id)
#  index_contact_emails_on_contact_id                 (contact_id)
#  index_contact_emails_on_contact_id_primary_unique  (contact_id) UNIQUE WHERE ("primary" = true)
#  index_contact_emails_on_lower_email_account_id     (lower((email)::text), account_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => cascade
#  fk_rails_...  (contact_id => contacts.id) ON DELETE => cascade
#
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
