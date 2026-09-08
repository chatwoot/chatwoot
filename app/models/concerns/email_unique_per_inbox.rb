module EmailUniquePerInbox
  extend ActiveSupport::Concern

  private

  def lock_inbox_emails(email:, inbox_ids:)
    return if email.blank?

    inbox_ids.compact.uniq.sort.each do |inbox_id|
      ApplicationRecord.connection.execute(
        ApplicationRecord.sanitize_sql_array(['SELECT pg_advisory_xact_lock(hashtext(?))', "contact_email:#{inbox_id}:#{email.downcase}"])
      )
    end
  end

  def email_conflict_in_inbox?(email:, inbox_id:, except_contact_id:)
    Contact
      .joins(:contact_inboxes)
      .where('lower(contacts.email) = ?', email.downcase)
      .where(contact_inboxes: { inbox_id: inbox_id })
      .where.not(contacts: { id: except_contact_id })
      .exists?
  end
end
