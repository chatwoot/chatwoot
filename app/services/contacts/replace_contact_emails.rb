class Contacts::ReplaceContactEmails
  attr_reader :contact, :emails, :legacy_email

  def initialize(contact:, emails:, legacy_email: nil)
    @contact = contact
    @emails = emails
    @legacy_email = legacy_email
  end

  def perform
    normalized_emails = normalized_email_list

    Contact.transaction do
      if normalized_emails.empty?
        replace_with_empty_list
      else
        replace_with_emails(normalized_emails)
      end
    end
  end

  private

  def replace_with_empty_list
    contact.contact_emails.destroy_all
    mirror_legacy_email(nil)
  end

  def replace_with_emails(normalized_emails)
    primary_email = normalized_emails.first

    contact.contact_emails.where.not(email: normalized_emails).destroy_all
    contact.contact_emails.primary.where.not(email: primary_email).find_each do |contact_email|
      contact_email.update!(primary: false)
    end

    normalized_emails.each do |email|
      contact_email = contact.contact_emails.find_or_initialize_by(email: email)
      contact_email.account = contact.account
      contact_email.primary = email == primary_email
      contact_email.save! if contact_email.changed?
    end

    mirror_legacy_email(primary_email)
  end

  def normalized_email_list
    source_emails = emails.presence || [legacy_email]

    Array(source_emails).filter_map do |email|
      normalized_email = email.to_s.strip.downcase
      normalized_email.presence
    end.uniq
  end

  def mirror_legacy_email(email)
    return if contact.email == email

    # Avoid callback recursion while mirroring the already-validated primary identity.
    contact.update_columns(email: email, updated_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
  end
end

Contacts::ReplaceContactEmails.prepend_mod_with('Contacts::ReplaceContactEmails')
