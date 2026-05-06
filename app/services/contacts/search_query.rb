class Contacts::SearchQuery
  def self.sql
    [contact_sql, email_sql, phone_sql].join(' OR ')
  end

  def self.contact_sql
    <<~SQL.squish
      contacts.name ILIKE :search
      OR contacts.email ILIKE :search
      OR contacts.phone_number ILIKE :search
      OR contacts.identifier ILIKE :search
    SQL
  end
  private_class_method :contact_sql

  def self.email_sql
    <<~SQL.squish
      EXISTS (
        SELECT 1
        FROM contact_emails
        WHERE contact_emails.contact_id = contacts.id
          AND contact_emails.account_id = contacts.account_id
          AND contact_emails.email ILIKE :search
      )
    SQL
  end
  private_class_method :email_sql

  def self.phone_sql
    <<~SQL.squish
      EXISTS (
        SELECT 1
        FROM contact_phones
        WHERE contact_phones.contact_id = contacts.id
          AND contact_phones.account_id = contacts.account_id
          AND contact_phones.phone_number ILIKE :search
      )
    SQL
  end
  private_class_method :phone_sql
end
