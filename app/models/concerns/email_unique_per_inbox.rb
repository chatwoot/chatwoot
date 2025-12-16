module EmailUniquePerInbox
  extend ActiveSupport::Concern

  private

  def email_conflict_in_inbox?(email:, inbox_id:, except_contact_id:)
    Contact
      .joins(:contact_inboxes)
      .where('lower(contacts.email) = ?', email.downcase)
      .where(contact_inboxes: { inbox_id: inbox_id })
      .where.not(contacts: { id: except_contact_id })
      .exists?
  end
end
