module ContactPointSearchable
  extend ActiveSupport::Concern

  included do
    scope :matching_email, lambda { |value|
      normalized = value.to_s.strip.downcase
      where('LOWER(contacts.email) = :email OR EXISTS (
        SELECT 1 FROM contact_emails
        WHERE contact_emails.contact_id = contacts.id
        AND contact_emails.account_id = contacts.account_id
        AND LOWER(contact_emails.email) = :email
      )', email: normalized)
    }

    scope :matching_phone_number, lambda { |value|
      normalized = value.to_s.strip
      where('contacts.phone_number = :phone OR EXISTS (
        SELECT 1 FROM contact_phones
        WHERE contact_phones.contact_id = contacts.id
        AND contact_phones.account_id = contacts.account_id
        AND contact_phones.phone_number = :phone
      )', phone: normalized)
    }
  end

  class_methods do
    def resolved_contacts(use_crm_v2: false)
      return where(contact_type: 'lead') if use_crm_v2

      where(<<~SQL.squish)
        contacts.email <> ''
        OR contacts.phone_number <> ''
        OR contacts.identifier <> ''
        OR EXISTS (
          SELECT 1
          FROM contact_emails
          WHERE contact_emails.contact_id = contacts.id
            AND contact_emails.account_id = contacts.account_id
        )
        OR EXISTS (
          SELECT 1
          FROM contact_phones
          WHERE contact_phones.contact_id = contacts.id
            AND contact_phones.account_id = contacts.account_id
        )
      SQL
    end

    def from_email(email)
      matching_email(email).first
    end

    def from_phone_number(phone_number)
      matching_phone_number(phone_number).first
    end
  end
end
