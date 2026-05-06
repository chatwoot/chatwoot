class Contacts::SyncPrimaryEmailIdentity
  attr_reader :contact

  def initialize(contact:)
    @contact = contact
  end

  def perform
    if contact.email.blank?
      sync_blank_primary_email
    else
      sync_present_primary_email
    end

    contact.association(:contact_emails).reset
  end

  private

  def sync_present_primary_email
    primary_contact_email = contact.contact_emails.find_or_initialize_by(email: contact.email)

    contact.contact_emails.primary.where.not(id: primary_contact_email.id).find_each do |contact_email|
      contact_email.update!(primary: false)
    end

    primary_contact_email.account = contact.account
    primary_contact_email.primary = true
    primary_contact_email.save! if primary_contact_email.changed?
  end

  def sync_blank_primary_email
    current_primary_email&.destroy!

    fallback_contact_email = remaining_contact_emails.first

    if fallback_contact_email.present?
      fallback_contact_email.update!(primary: true) unless fallback_contact_email.primary?
      mirror_legacy_email(fallback_contact_email.email)
    else
      mirror_legacy_email(nil)
    end
  end

  def current_primary_email
    contact.contact_emails.primary.first
  end

  def remaining_contact_emails
    contact.contact_emails.order(:id)
  end

  def mirror_legacy_email(email)
    return if contact.email == email

    # Avoid callback recursion while mirroring the selected primary identity.
    contact.update_columns(email: email, updated_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
  end
end

Contacts::SyncPrimaryEmailIdentity.prepend_mod_with('Contacts::SyncPrimaryEmailIdentity')
