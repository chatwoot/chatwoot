class ContactBuilder
  pattr_initialize [:source_id!, :inbox!, :contact_attributes!]

  def perform
    contact_inbox = inbox.contact_inboxes.find_by(source_id: source_id)
    return contact_inbox if contact_inbox

    build_contact
  end

  private

  def account
    @account ||= inbox.account
  end

  def build_contact
    ActiveRecord::Base.transaction do
      contact = account.contacts.create!(
        name: contact_attributes[:name],
        phone_number: contact_attributes[:phone_number],
        email: contact_attributes[:email],
        identifier: contact_attributes[:identifier],
        additional_attributes: contact_attributes[:additional_attributes]
      )
      contact_inbox = ::ContactInbox.create!(
        contact_id: contact.id,
        inbox_id: inbox.id,
        source_id: source_id
      )

      ::ContactAvatarJob.perform_later(contact, contact_attributes[:avatar_url]) if contact_attributes[:avatar_url]
      contact_inbox
    rescue StandardError => e
      Rails.logger e
    end
  end
end
