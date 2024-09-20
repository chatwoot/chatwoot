class FixContactInboxForLexlySe < ActiveRecord::Migration[7.0]
  def change
    contact_inbox = ContactInbox.find_by(id: 51088)
    contact = Contact.find_by(email: 'info@lexly.se')

    if contact_inbox && contact
      contact_inbox.update_columns(contact_id: contact.id)
    end
  end
end
