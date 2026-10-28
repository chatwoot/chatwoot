# Email is unique per account unless phone numbers tell contacts apart: two contacts may share an
# email as long as both have a phone number and the numbers differ (a family or front desk sharing
# one inbox). A contact without a phone number conflicts with every other contact that has its email.
#
# The partial unique indexes backing this can't express that last rule, so two inserts racing to
# create the same brand-new email, one with a phone number and one without, aren't serialized by
# the database. ContactIdentifyAction isn't exposed to that for an existing email: it merges into
# the existing contact instead of inserting a new row whenever that contact has no phone number.
module ContactEmailIdentity
  extend ActiveSupport::Concern

  included do
    # A whitespace-only phone would otherwise count as a real one, both here and in the indexes
    before_validation { self.phone_number = phone_number.presence }
    validate :validate_email_uniqueness
  end

  class_methods do
    # Once a phone number is known, only a same-email contact with that phone, or with none, is the
    # same contact. Without a phone number, email alone still decides.
    def from_email_and_phone_number(email, phone_number)
      return from_email(email) if phone_number.blank?

      contacts = where(email: email&.downcase)
      contacts.find_by(phone_number: phone_number) || contacts.find_by(phone_number: [nil, ''])
    end

    def email_taken?(email, phone_number, except_id: nil)
      contacts = where(arel_table[:email].lower.eq(email.downcase)).where.not(id: except_id)
      contacts = contacts.where(phone_number: [nil, '', phone_number]) if phone_number.present?
      contacts.exists?
    end
  end

  private

  def validate_email_uniqueness
    errors.add(:email, :taken) if email.present? && account.contacts.email_taken?(email, phone_number, except_id: id)
  end
end
