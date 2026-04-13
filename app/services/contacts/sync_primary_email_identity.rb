class Contacts::SyncPrimaryEmailIdentity
  attr_reader :contact

  def initialize(contact:)
    @contact = contact
  end

  def perform
    return clear_contact_emails if contact.email.blank?

    primary_contact_email = contact.contact_emails.find_or_initialize_by(email: contact.email)

    contact.contact_emails.where.not(id: primary_contact_email.id).update_all(primary: false, updated_at: Time.current)

    primary_contact_email.account = contact.account
    primary_contact_email.primary = true
    primary_contact_email.save! if primary_contact_email.changed?
  end

  private

  def clear_contact_emails
    contact.contact_emails.destroy_all
  end
end

Contacts::SyncPrimaryEmailIdentity.prepend_mod_with('Contacts::SyncPrimaryEmailIdentity')
